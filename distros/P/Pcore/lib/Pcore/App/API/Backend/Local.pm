package Pcore::App::API::Backend::Local;

use Pcore -role, -result;
use Pcore::Util::Data qw[to_b64_url];
use Pcore::Util::Digest qw[sha3_512];
use Pcore::App::API qw[:CONST];
use Pcore::Util::Text qw[encode_utf8];
use Pcore::Util::UUID qw[create_uuid];

with qw[Pcore::App::API::Backend];

requires(

    # INIT
    'init_db',

    # AUTH
    '_auth_user_password',
    '_auth_app_instance_token',
    '_auth_user_token',
    '_auth_user_session',
);

has dbh => ( is => 'ro', isa => ConsumerOf ['Pcore::Handle::DBI'], required => 1 );

has _hash_rpc   => ( is => 'ro', isa => InstanceOf ['Pcore::Util::PM::RPC'],       init_arg => undef );
has _hash_cache => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Hash::RandKey'], init_arg => undef );
has _hash_cache_size => ( is => 'ro', isa => PositiveInt, default => 10_000 );

sub _build_is_local ($self) {
    return 1;
}

sub _build_host ($self) {
    return 'local';
}

# INIT
sub init ( $self, $cb ) {
    $self->{_hash_cache} = P->hash->limited( $self->{_hash_cache_size} );

    $self->init_db(
        sub {

            # create hash RPC
            P->pm->run_rpc(
                'Pcore::App::API::RPC::Hash',
                workers   => undef,
                buildargs => {
                    argon2_time        => 3,
                    argon2_memory      => '64M',
                    argon2_parallelism => 1,
                },
                on_ready => sub ($rpc) {
                    $self->{_hash_rpc} = $rpc;

                    $rpc->connect_rpc(
                        on_connect => sub ($rpc) {
                            $cb->( result 200 );

                            return;
                        }
                    );

                    return;
                },
            );

            return;
        }
    );

    return;
}

# REGISTER APP INSTANCE
# create app, add app permissions, create app instance
sub register_app_instance ( $self, $app_name, $app_desc, $app_permissions, $app_instance_host, $app_instance_version, $cb ) {

    # create app
    $self->create_app(
        $app_name,
        $app_desc,
        $app_permissions,
        sub ($app) {

            # app creation error
            if ( !$app && $app != 304 ) {
                $cb->($app);
            }

            # app created
            else {

                # create app instalnce
                $self->create_app_instance(
                    $app->{data}->{id},
                    $app_instance_host,
                    $app_instance_version,
                    sub ($app_instance) {

                        # app instance creation error
                        if ( !$app_instance ) {
                            $cb->($app_instance);
                        }

                        # app instance created
                        else {
                            $cb->( result 200, app_id => $app->{data}->{id}, app_instance_id => $app_instance->{data}->{id}, app_instance_token => $app_instance->{data}->{token} );
                        }

                        return;
                    }
                );
            }

            return;
        }
    );

    return;
}

# CONNECT APP INSTANCE
# add app permissions, check, that all permissions are approved, update app instance, add app roles
sub connect_app_instance ( $self, $app_instance_id, $app_instance_version, $app_roles, $app_permissions, $cb ) {

    # get app instance
    $self->get_app_instance(
        $app_instance_id,
        sub ($app_instance) {

            # get app instance error
            if ( !$app_instance ) {
                $cb->($app_instance);
            }

            # get app instance ok
            else {

                # get app
                $self->get_app(
                    $app_instance->{data}->{app_id},
                    sub ($app) {

                        # get app error
                        if ( !$app ) {
                            $cb->($app);
                        }

                        # get app ok
                        else {

                            # add app permissions
                            $self->add_app_permissions(
                                $app->{data}->{id},
                                $app_permissions,
                                sub ($res) {

                                    # add app permissions error
                                    if ( !$res && $res != 304 ) {
                                        $cb->($res);
                                    }
                                    else {

                                        # check, that all app permissions are approved
                                        $self->check_app_permissions_approved(
                                            $app->{data}->{id},
                                            sub ($res) {

                                                # app permissions are not approved
                                                if ( !$res ) {
                                                    $cb->($res);
                                                }

                                                # app permisisons are approved
                                                else {

                                                    # updating app instance
                                                    $self->update_app_instance(
                                                        $app_instance_id,
                                                        $app_instance_version,
                                                        sub ($res) {

                                                            # app instance update error
                                                            if ( !$res ) {
                                                                $cb->($res);
                                                            }

                                                            # app instance updated
                                                            else {

                                                                # add app roles
                                                                $self->add_app_roles(
                                                                    $app->{data}->{id},
                                                                    $app_roles,
                                                                    sub($res) {

                                                                        # app roles error
                                                                        if ( !$res && $res != 304 ) {
                                                                            $cb->($res);
                                                                        }

                                                                        # app roles added
                                                                        else {
                                                                            $cb->( result 200 );
                                                                        }

                                                                        return;
                                                                    }
                                                                );
                                                            }

                                                            return;
                                                        }
                                                    );
                                                }

                                                return;
                                            }
                                        );
                                    }

                                    return;
                                }
                            );

                            return;
                        }

                        return;
                    }
                );
            }

            return;
        }
    );

    return;
}

# AUTH
# NOTE this method should be accessible only for applications
sub auth_token ( $self, $app_instance_id, $private_token, $cb ) {
    if ( $private_token->[0] == $TOKEN_TYPE_USER_PASSWORD ) {
        $self->_auth_user_password( $app_instance_id, $private_token, $cb );
    }
    elsif ( $private_token->[0] == $TOKEN_TYPE_APP_INSTANCE_TOKEN ) {
        $self->_auth_app_instance_token( $app_instance_id, $private_token, $cb );
    }
    elsif ( $private_token->[0] == $TOKEN_TYPE_USER_TOKEN ) {
        $self->_auth_user_token( $app_instance_id, $private_token, $cb );
    }
    elsif ( $private_token->[0] == $TOKEN_TYPE_USER_SESSION ) {
        $self->_auth_user_session( $app_instance_id, $private_token, $cb );
    }
    else {
        $cb->( result [ 400, 'Invalid token type' ] );
    }

    return;
}

# TOKEN / HASH GENERATORS
sub _generate_token ( $self, $token_type, $salt, $cb ) {
    my $token_id = create_uuid;

    my $public_token = to_b64_url pack( 'C', $token_type ) . $token_id->bin . P->random->bytes(32);

    my $private_token = sha3_512 $public_token;

    $self->_hash_rpc->rpc_call(
        'create_hash',
        $private_token . encode_utf8($salt),
        sub ( $res ) {
            if ( !$res ) {
                $cb->($res);
            }
            else {
                $cb->( result 200, { id => $token_id->str, token => $public_token, hash => $res->{hash} } );
            }

            return;
        }
    );

    return;
}

sub _generate_user_password_hash ( $self, $user_name_utf8, $user_password_utf8, $user_id, $cb ) {
    my $user_name_bin = encode_utf8 $user_name_utf8;

    my $user_password_bin = encode_utf8 $user_password_utf8;

    my $private_token = sha3_512 $user_password_bin . $user_name_bin;

    $self->_hash_rpc->rpc_call(
        'create_hash',
        $private_token . $user_id,
        sub ( $res ) {
            if ( !$res ) {
                $cb->($res);
            }
            else {
                $cb->( result 200, { hash => $res->{hash} } );
            }

            return;
        }
    );

    return;
}

sub _verify_token_hash ( $self, $private_token, $hash, $salt, $cb ) {
    my $cache_id = "$salt/$hash/$private_token";

    if ( exists $self->{_hash_cache}->{$cache_id} ) {
        $cb->( $self->{_hash_cache}->{$cache_id} );
    }
    else {
        $self->_hash_rpc->rpc_call(
            'verify_hash',
            $private_token . $salt,
            $hash,
            sub ( $res ) {
                $cb->( $self->{_hash_cache}->{$cache_id} = $res->{match} ? result 200 : result [ 400, 'Invalid token' ] );

                return;
            }
        );
    }

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 78, 126, 245, 291,   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |      | 316                  |                                                                                                                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 200                  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 266                  | * Private subroutine/method '_generate_token' declared but not used                                            |
## |      | 291                  | * Private subroutine/method '_generate_user_password_hash' declared but not used                               |
## |      | 316                  | * Private subroutine/method '_verify_token_hash' declared but not used                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
