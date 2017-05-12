package Pcore::App::API;

use Pcore -role, -const, -result, -export => { CONST => [qw[$TOKEN_TYPE $TOKEN_TYPE_USER_PASSWORD $TOKEN_TYPE_APP_INSTANCE_TOKEN $TOKEN_TYPE_USER_TOKEN $TOKEN_TYPE_USER_SESSION]] };
use Pcore::App::API::Map;
use Pcore::Util::Data qw[from_b64 from_b64_url];
use Pcore::Util::Digest qw[sha3_512];
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::UUID qw[create_uuid_from_bin uuid_str];
use Pcore::App::API::Auth::Cache;

const our $TOKEN_TYPE_USER_PASSWORD      => 1;
const our $TOKEN_TYPE_APP_INSTANCE_TOKEN => 2;
const our $TOKEN_TYPE_USER_TOKEN         => 3;
const our $TOKEN_TYPE_USER_SESSION       => 4;

const our $TOKEN_TYPE => {
    $TOKEN_TYPE_USER_PASSWORD      => undef,
    $TOKEN_TYPE_APP_INSTANCE_TOKEN => undef,
    $TOKEN_TYPE_USER_TOKEN         => undef,
    $TOKEN_TYPE_USER_SESSION       => undef,
};

require Pcore::App::API::Auth;

requires qw[_build_roles];

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has map => ( is => 'ro', isa => InstanceOf ['Pcore::App::API::Map'], init_arg => undef );
has roles => ( is => 'ro', isa => HashRef, init_arg => undef );    # API roles, provided by this app
has permissions => ( is => 'ro', isa => Maybe [ArrayRef], init_arg => undef );    # foreign app roles, that this app can use
has backend => ( is => 'ro', isa => ConsumerOf ['Pcore::App::API::Backend'], init_arg => undef );

has auth_cache => ( is => 'ro', isa => InstanceOf ['Pcore::App::API::Auth::Cache'], init_arg => undef );
has _auth_cb_cache => ( is => 'ro', isa => HashRef, default => sub { {} }, init_arg => undef );

around _build_roles => sub ( $orig, $self ) {
    my $roles = $self->$orig;

    die q[App must provide roles] if !keys $roles->%*;

    # validate roles
    for my $role ( keys $roles->%* ) {

        # check, that role has description
        die qq[API role "$role" requires description] if !$roles->{$role};
    }

    return $roles;
};

# NOTE this method can be redefined in app instance
sub _build_permissions ($self) {
    return;
}

sub validate_name ( $self, $name ) {

    # name looks like UUID string
    return if $name =~ /\A[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\z/sm;

    return if $name =~ /[^[:alnum:]_@.-]/smi;

    return 1;
}

# INIT API
sub init_api ($self) {
    print 'Scanning API ... ';

    # build roles
    $self->{roles} = $self->_build_roles;

    # build permissions
    $self->{permissions} = $self->_build_permissions;

    # create auth cache object
    $self->{auth_cache} = Pcore::App::API::Auth::Cache->new( { app => $self->{app} } );

    # build map
    # using class name as string to avoid conflict with Type::Standard Map subroutine, exported to Pcore::App::API
    $self->{map} = 'Pcore::App::API::Map'->new( { app => $self->app } );

    # init map
    $self->{map}->method;

    say 'done';

    return;
}

sub connect_api ( $self, $cb ) {

    # build API auth backend
    my $auth_uri = P->uri( $self->{app}->{auth} );

    print q[Creating API backend ... ];

    if ( $auth_uri->scheme eq 'sqlite' || $auth_uri->scheme eq 'pgsql' ) {
        my $dbh = P->handle($auth_uri);

        my $class = P->class->load( $dbh->uri->scheme, ns => 'Pcore::App::API::Backend::Local' );

        $self->{backend} = $class->new( { app => $self->app, dbh => $dbh } );
    }
    elsif ( $auth_uri->scheme eq 'http' || $auth_uri->scheme eq 'https' || $auth_uri->scheme eq 'ws' || $auth_uri->scheme eq 'wss' ) {
        require Pcore::App::API::Backend::Remote;

        $self->{backend} = Pcore::App::API::Backend::Remote->new( { app => $self->app, uri => $auth_uri } );
    }
    else {
        die q[Unknown API auth scheme];
    }

    say 'done';

    print q[Initialising API backend ... ];

    $self->{backend}->init(
        sub ($res) {
            die qq[Error initialising API auth backend: $res] if !$res;

            say 'done';

            my $connect_app_instance = sub {
                print q[Connecting app instance ... ];

                $self->{backend}->connect_app_instance(
                    $self->app->{instance_id},
                    "@{[$self->app->version]}",
                    $self->roles,
                    $self->permissions,
                    sub ($res) {
                        say $res;

                        if ( !$res ) {
                            $cb->($res);
                        }
                        else {
                            if ( $self->{backend}->is_local ) {

                                # create root user
                                $self->{backend}->create_root_user(
                                    sub ($res) {

                                        # root user creation error
                                        if ( !$res && $res != 304 ) {
                                            $cb->($res);
                                        }

                                        # root user created
                                        else {
                                            say qq[Root password: $res->{data}->{root_password}] if $res;

                                            $cb->( result 200 );
                                        }

                                        return;
                                    }
                                );
                            }
                            else {
                                $cb->($res);
                            }
                        }

                        return;
                    }
                );

                return;
            };

            # get app instance credentials from local config
            $self->app->{id}             = $self->app->cfg->{auth}->{ $self->{backend}->host }->[0];
            $self->app->{instance_id}    = $self->app->cfg->{auth}->{ $self->{backend}->host }->[1];
            $self->app->{instance_token} = $self->app->cfg->{auth}->{ $self->{backend}->host }->[2];

            # sending app instance registration request
            if ( !$self->app->{instance_token} ) {
                print q[Sending app instance registration request ... ];

                # register app on backend, get and init message broker
                $self->{backend}->register_app_instance(
                    $self->app->name,
                    $self->app->desc,
                    $self->permissions,
                    P->sys->hostname,
                    "@{[$self->app->version]}",
                    sub ( $res ) {
                        die qq[Error registering app: $res] if !$res;

                        say 'done';

                        # store app instance credentials
                        {
                            $self->app->{id}             = $self->app->cfg->{auth}->{ $self->{backend}->host }->[0] = $res->{app_id};
                            $self->app->{instance_id}    = $self->app->cfg->{auth}->{ $self->{backend}->host }->[1] = $res->{app_instance_id};
                            $self->app->{instance_token} = $self->app->cfg->{auth}->{ $self->{backend}->host }->[2] = $res->{app_instance_token};

                            $self->app->store_cfg;
                        }

                        # connect app instance
                        $connect_app_instance->();

                        return;
                    }
                );
            }

            # connecting app instance
            else {
                $connect_app_instance->();
            }

            return;
        }
    );

    return;
}

# AUTHENTICATE
sub authenticate ( $self, $user_name_utf8, $token, $cb ) {

    # no auth token provided
    if ( !defined $token ) {
        $cb->( bless { app => $self->{app} }, 'Pcore::App::API::Auth' );

        return;
    }

    my ( $token_type, $token_id, $private_token );

    # authenticate user password
    if ($user_name_utf8) {

        # generate private token
        $private_token = eval { sha3_512 encode_utf8($token) . encode_utf8 $user_name_utf8 };

        # error decoding token
        if ($@) {
            $cb->( bless { app => $self->{app} }, 'Pcore::App::API::Auth' );

            return;
        }

        $token_type = $TOKEN_TYPE_USER_PASSWORD;

        \$token_id = \$user_name_utf8;
    }

    # authenticate token
    else {

        # decode token
        eval {
            my $token_bin = from_b64_url $token;

            # unpack token type
            $token_type = unpack 'C', $token_bin;

            # unpack token id
            $token_id = create_uuid_from_bin( substr $token_bin, 1, 16 )->str;

            $private_token = sha3_512 $token;
        };

        # error decoding token
        if ($@) {
            $cb->( bless { app => $self->{app} }, 'Pcore::App::API::Auth' );

            return;
        }

        # invalid token type
        if ( !exists $TOKEN_TYPE->{$token_type} ) {
            $cb->( bless { app => $self->{app} }, 'Pcore::App::API::Auth' );

            return;
        }
    }

    $self->authenticate_private( [ $token_type, $token_id, $private_token ], $cb );

    return;
}

# TODO link tags
sub authenticate_private ( $self, $private_token, $cb ) {
    my $auth;

    # get auth_id by private token
    my $auth_id = $self->{auth_cache}->{private_token}->{ $private_token->[2] };

    # get cached auth, if private token is cached and has associated auth id
    $auth = $self->{auth_cache}->{auth}->{$auth_id} if $auth_id;

    if ($auth) {
        $cb->($auth);

        return;
    }

    push $self->{_auth_cb_cache}->{ $private_token->[2] }->@*, $cb;

    return if $self->{_auth_cb_cache}->{ $private_token->[2] }->@* > 1;

    # authenticate on backend
    $self->{backend}->auth_token(
        $self->{app}->{instance_id},
        $private_token,
        sub ( $res ) {

            # get auth_id by private token
            $auth_id = $self->{auth_cache}->{private_token}->{ $private_token->[2] };

            # authentication error
            if ( !$res ) {

                # invalidate auth, if auth id was cached
                $self->{auth_cache}->remove_auth($auth_id) if $auth_id;

                # return new unauthenticated auth object
                $auth = bless { app => $self->{app} }, 'Pcore::App::API::Auth';
            }

            # authenticated
            else {

                # generate new auth_id, if auth wasn't cached yet
                if ( !$auth_id ) {
                    $auth_id = $self->{auth_cache}->{private_token}->{ $private_token->[2] } = uuid_str;
                }

                # or try to get auth from cache
                else {
                    $auth = $self->{auth_cache}->{auth}->{$auth_id};
                }

                # auth is cached
                if ($auth) {

                    # update auth permissions
                    $auth->{permissions} = $res->{data}->{auth}->{permisions};
                }

                # auth wasn't cached
                else {

                    # create new auth object
                    $auth = $self->{auth_cache}->{auth}->{$auth_id} = bless $res->{data}->{auth}, 'Pcore::App::API::Auth';

                    $auth->{app} = $self->{app};
                    $auth->{id}  = $auth_id;

                    # TODO tags
                    # my $tags = $res->{data}->{tags};
                }
            }

            # call callbacks
            while ( my $cb = shift $self->{_auth_cb_cache}->{ $private_token->[2] }->@* ) {
                $cb->($auth);
            }

            delete $self->{_auth_cb_cache}->{ $private_token->[2] };

            return;
        }
    );

    return;
}

# APP
sub get_app ( $self, $app_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->get_app(
        $app_id,
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub remove_app ( $self, $app_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->remove_app(
        $app_id,
        sub ( $res ) {

            # invalidate app cache on success
            if ($res) {

                # $self->_invalidate_app_cache($app_id);
            }

            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# APP INSTANCE
sub get_app_instance ( $self, $app_instance_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->get_app_instance(
        $app_instance_id,
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub remove_app_instance ( $self, $app_instance_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->remove_app_instance(
        $app_instance_id,
        sub ( $res ) {

            # invalidate app instance cache on success
            if ($res) {

                # $self->_invalidate_app_instance_cache($app_instance_id);
            }

            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# USER
sub get_users ( $self, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->get_users(
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub get_user ( $self, $user_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->get_user(
        $user_id,
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub create_user ( $self, $base_user, $user_name, $password, $enabled, $permissions, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->create_user(
        $base_user,
        $user_name,
        $password,
        $enabled,
        $permissions,
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub set_user_password ( $self, $user_id, $user_password_utf8, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->set_user_password(
        $user_id,
        encode_utf8($user_password_utf8),
        sub ($res) {

            # invalidate user cache on success
            if ($res) {

                # $self->on_user_password_change($user_id);
            }

            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub set_user_enabled ( $self, $user_id, $enabled, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->set_user_enabled(
        $user_id, $enabled,
        sub ($res) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub remove_user ( $self, $user_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->remove_user(
        $user_id,
        sub ($res) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# USER TOKEN
sub create_user_token ( $self, $user_id, $desc, $permissions, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->create_user_token(
        $user_id, $desc,
        $permissions,
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub remove_user_token ( $self, $user_token_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->remove_user_token(
        $user_token_id,
        sub ( $res ) {

            # invalidate user token cache on success
            if ($res) {

                # $self->_invalidate_user_token_cache($token_id);
            }

            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# USER SESSION
sub create_user_session ( $self, $user_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->create_user_session(
        $user_id,
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

sub remove_user_session ( $self, $user_session_id, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->{backend}->remove_user_session(
        $user_session_id,
        sub ( $res ) {
            $cb->($res) if $cb;

            $blocking_cv->($res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 60                   | RegularExpressions::ProhibitComplexRegexes - Split long regexps into smaller qr// chunks                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 225, 495, 516, 576   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 258                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
