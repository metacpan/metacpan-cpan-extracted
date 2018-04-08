package Pcore::App::API;

use Pcore -role, -result, -const, -export => { CONST => [qw[$TOKEN_TYPE $TOKEN_TYPE_USER_PASSWORD $TOKEN_TYPE_USER_TOKEN $TOKEN_TYPE_USER_SESSION]] };
use Pcore::App::API::Map;
use Pcore::App::API::Auth;
use Pcore::Util::Data qw[from_b64 from_b64_url];
use Pcore::Util::Digest qw[sha3_512];
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::UUID qw[uuid_from_bin];

has app => ( is => 'ro', isa => ConsumerOf ['Pcore::App'], required => 1 );

has map => ( is => 'ro', isa => InstanceOf ['Pcore::App::API::Map'], init_arg => undef );

has _auth_cb_queue => ( is => 'ro', isa => HashRef, init_arg => undef );
has _auth_cache    => ( is => 'ro', isa => HashRef, init_arg => undef );

const our $TOKEN_TYPE_USER_PASSWORD => 1;
const our $TOKEN_TYPE_USER_TOKEN    => 3;
const our $TOKEN_TYPE_USER_SESSION  => 4;

const our $TOKEN_TYPE => {
    $TOKEN_TYPE_USER_PASSWORD => undef,
    $TOKEN_TYPE_USER_TOKEN    => undef,
    $TOKEN_TYPE_USER_SESSION  => undef,
};

sub new ( $self, $app ) {
    state $scheme_class = {
        sqlite => 'Pcore::App::API::Local::sqlite',
        pgsql  => 'Pcore::App::API::Local::pgsql',
        ws     => 'Pcore::App::API::Local::Remote',
        wss    => 'Pcore::App::API::Local::Remote',
    };

    if ( defined $app->{app_cfg}->{api}->{connect} ) {
        my $uri = P->uri( $app->{app_cfg}->{api}->{connect} );

        if ( my $class = $scheme_class->{ $uri->scheme } ) {
            return P->class->load($class)->new( { app => $app } );
        }
        else {
            die 'Unknown API scheme';
        }
    }
    else {
        return P->class->load('Pcore::App::API::LocalNoAuth')->new( { app => $app } );
    }
}

# setup events listeners
around init => sub ( $orig, $self, $cb ) {

    # build map
    # using class name as string to avoid conflict with Type::Standard Map subroutine, exported to Pcore::App::API
    $self->{map} = 'Pcore::App::API::Map'->new( { app => $self->{app} } );

    # init map
    print 'Scanning API classes ... ';
    $self->{map}->init;
    say 'done';

    # setup events listeners
    P->listen_events(
        'APP.API.AUTH',
        sub ($ev) {
            $self->{_auth_cache}->%* = ();

            return;
        }
    );

    $self->$orig($cb);

    return;
};

# AUTHENTICATE
# parse token, create private token, forward to authenticate_private
sub authenticate ( $self, $user_name_utf8, $token, $cb ) {

    # no auth token provided
    if ( !defined $token ) {
        $cb->( bless { app => $self->{app} }, 'Pcore::App::API::Auth' );

        return;
    }

    my ( $token_type, $token_id, $private_token_hash );

    # authenticate user password
    if ($user_name_utf8) {

        # generate private token hash
        $private_token_hash = eval { sha3_512 encode_utf8($token) . encode_utf8 $user_name_utf8 };

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
            $token_id = uuid_from_bin( substr $token_bin, 1, 16 )->str;

            $private_token_hash = sha3_512 $token;
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

    $self->authenticate_private( [ $token_type, $token_id, $private_token_hash ], $cb );

    return;
}

sub authenticate_private ( $self, $private_token, $cb ) {

    # try to find token in cache
    my $auth = $self->{_auth_cache}->{ $private_token->[2] };

    # token was cached
    if ($auth) {
        $cb->($auth);

        return;
    }

    push $self->{_auth_cb_queue}->{ $private_token->[2] }->@*, $cb;

    return if $self->{_auth_cb_queue}->{ $private_token->[2] }->@* > 1;

    # authenticate on backend
    $self->do_authenticate_private(
        $private_token,
        sub ( $res ) {

            # authentication error
            if ( !$res ) {

                # delete private token from cache
                delete $self->{_auth_cache}->{ $private_token->[2] };

                # return new unauthenticated auth object
                $auth = bless {
                    app              => $self->{app},
                    is_authenticated => 0,
                    private_token    => $private_token,
                  },
                  'Pcore::App::API::Auth';
            }

            # authenticated
            else {

                # create auth
                $auth = bless $res->{data}, 'Pcore::App::API::Auth';

                $auth->{app}              = $self->{app};
                $auth->{is_authenticated} = 1;
                $auth->{private_token}    = $private_token;

                # store in cache
                $self->{_auth_cache}->{ $private_token->[2] } = $auth;
            }

            # call callbacks
            while ( my $cb = shift $self->{_auth_cb_queue}->{ $private_token->[2] }->@* ) {
                $cb->($auth);
            }

            delete $self->{_auth_cb_queue}->{ $private_token->[2] };

            return;
        }
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 80                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 113                  | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
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

=head1 AUTHENTICATION METHODS

=head2 authentocate( $user_name, $token, $cb )

Performs user authentication and returns instance of Pcore::App::API::Auth.

C<$user_name> can be undefined.

=head2 authentocate_private( $private_token, $cb )

Performs private token authentication and returns instance of Pcore::App::API::Auth.

Private token structure is [ %token_type, $token_id, $token_hash ].

=head1 USER METHODS

=head2 create_user ( $user_name, $password, $enabled, $permissions, $cb )

Creates user and returns user id.

C<$permissions> - ArrayRef[ 'role1', 'role2', ... ]

=head2 get_users ( $cb )

Returns all users.

=head1 SEE ALSO

=cut
