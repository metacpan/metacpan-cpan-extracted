package Pcore::App::API::Backend::Local::sqlite::UserToken;

use Pcore -role, -result;
use Pcore::App::API qw[:CONST];
use Pcore::Util::UUID qw[uuid_str];
use Pcore::Util::Text qw[encode_utf8];

# TODO tags
sub _auth_user_token ( $self, $source_app_instance_id, $private_token, $cb ) {
    state $q1 = <<'SQL';
        SELECT
            api_app_role.name AS app_role_name
        FROM
            api_app_instance,
            api_app_role,
            api_user_permission,
            api_user_token_permission
        WHERE
            api_app_instance.id = ?
            AND api_app_role.app_id = api_app_instance.app_id
            AND api_app_role.id = api_user_permission.app_role_id
            AND api_user_permission.id = api_user_token_permission.user_permission_id
            AND api_user_token_permission.user_token_id = ?
SQL

    # get user token
    my $user_token = $self->dbh->selectrow(
        <<'SQL',
            SELECT
                api_user.id AS user_id,
                api_user.name AS user_name,
                api_user.enabled AS user_enabled,
                api_user_token.hash AS user_token_hash
            FROM
                api_user,
                api_user_token
            WHERE
                api_user.id = api_user_token.user_id
                AND api_user_token.id = ?
SQL
        [ $private_token->[1] ]
    );

    # user token not found
    if ( !$user_token ) {
        $cb->( result [ 404, 'User token not found' ] );

        return;
    }

    # user disabled
    if ( !$user_token->{user_enabled} ) {
        $cb->( result [ 404, 'User disabled' ] );

        return;
    }

    # verify token
    $self->_verify_token_hash(
        $private_token->[2],
        $user_token->{user_token_hash},
        encode_utf8( $user_token->{user_id} ),
        sub ($status) {

            # token is not valid
            if ( !$status ) {
                $cb->($status);
            }

            # token is valid
            else {
                my $auth = {
                    private_token => $private_token,

                    is_user   => 1,
                    is_root   => 0,
                    user_id   => $user_token->{user_id},
                    user_name => $user_token->{user_name},

                    is_app          => 0,
                    app_id          => undef,
                    app_instance_id => undef,

                    permissions => {},
                };

                my $tags = {};

                # get permissions
                if ( my $roles = $self->dbh->selectall( $q1, [ $source_app_instance_id, $private_token->[1] ] ) ) {
                    $auth->{permissions} = { map { $_->{app_role_name} => 1 } $roles->@* };
                }

                $cb->( result 200, { auth => $auth, tags => $tags } );
            }

            return;
        }
    );

    return;
}

sub create_user_token ( $self, $user_id, $desc, $permissions, $cb ) {

    # get user
    $self->get_user(
        $user_id,
        sub ($user) {

            # get user error
            if ( !$user ) {
                $cb->($user);
            }

            # get user ok
            else {

                # root user can't have token
                if ( $user->{data}->{name} eq 'root' ) {
                    $cb->( result [ 400, 'Error creation token for root user' ] );
                }
                else {

                    # resolve permisisons
                    $self->resolve_app_roles(
                        $permissions,
                        sub ($roles) {

                            # error resolving permisions
                            if ( !$roles ) {
                                $cb->($roles);
                            }

                            # permissions resolved
                            else {

                                # get user permissions
                                $self->get_user_permissions(
                                    $user->{data}->{id},
                                    sub ($user_permissions) {

                                        # user permissions get error
                                        if ( !$user_permissions ) {
                                            $cb->($user_permissions);
                                        }

                                        # user permissions ok
                                        else {

                                            # compare token and user permissions
                                            for my $role_id ( keys $roles->{data}->%* ) {

                                                # user permission is not set
                                                if ( !$user_permissions->{data}->{$role_id}->{user_permission_id} ) {
                                                    $cb->( result [ 400, q[Invalid user token permissions] ] );

                                                    return;
                                                }
                                            }

                                            # generate user token
                                            $self->_generate_token(
                                                $TOKEN_TYPE_USER_TOKEN,
                                                $user->{data}->{id},
                                                sub ($user_token) {

                                                    # user token generation error
                                                    if ( !$user_token ) {
                                                        $cb->($user_token);
                                                    }

                                                    # user token generated
                                                    else {
                                                        my $dbh = $self->dbh;

                                                        $dbh->begin_work;

                                                        # insert user token
                                                        my $token_created = $dbh->do( q[INSERT OR IGNORE INTO api_user_token (id, user_id, desc, created_ts, hash) VALUES (?, ?, ?, ?, ?)], [ $user_token->{data}->{id}, $user->{data}->{id}, $desc // q[], time, $user_token->{data}->{hash} ] );

                                                        if ( !$token_created ) {
                                                            $dbh->rollback;

                                                            $cb->( result [ 500, 'User token creation error' ] );
                                                        }

                                                        # create user token permissions
                                                        else {
                                                            for my $role_id ( keys $roles->{data}->%* ) {

                                                                # create user permission
                                                                my $permission_created = $dbh->do( q[INSERT INTO api_user_token_permission (id, user_token_id, user_permission_id) VALUES (?, ?, ?)], [ uuid_str, $user_token->{data}->{id}, $user_permissions->{data}->{$role_id}->{user_permission_id} ] );

                                                                # user permission is not set
                                                                if ( !$permission_created ) {
                                                                    $dbh->rollback;

                                                                    $cb->( result [ 500, q[Error creation user token permissions] ] );

                                                                    return;
                                                                }
                                                            }

                                                            $dbh->commit;

                                                            $cb->(
                                                                result 201,
                                                                {   id    => $user_token->{data}->{id},
                                                                    type  => $TOKEN_TYPE_USER_TOKEN,
                                                                    token => $user_token->{data}->{token},
                                                                }
                                                            );
                                                        }
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
            }

            return;
        }
    );

    return;
}

sub remove_user_token ( $self, $user_token_id, $cb ) {
    if ( $self->dbh->do( q[DELETE OR IGNORE FROM api_user_token WHERE id = ?], [$user_token_id] ) ) {
        $cb->( result 200 );
    }
    else {
        $cb->( result [ 404, 'User token not found' ] );
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
## |    3 | 9, 104               | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 9                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_auth_user_token' declared but not  |
## |      |                      | used                                                                                                           |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 155, 182, 190, 196   | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::sqlite::UserToken

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
