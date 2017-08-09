package Pcore::App::API::Backend::Local::sqlite::UserSession;

use Pcore -role, -result;
use Pcore::App::API qw[:CONST];
use Pcore::Util::Text qw[encode_utf8];

sub _auth_user_session ( $self, $source_app_instance_id, $private_token, $cb ) {
    state $q1 = <<'SQL';
        SELECT
            api_app_role.name AS app_role_name
        FROM
            api_app_instance,
            api_app_role,
            api_user_permission
        WHERE
            api_app_instance.id = ?
            AND api_app_role.app_id = api_app_instance.app_id
            AND api_app_role.id = api_user_permission.app_role_id
            AND api_user_permission.user_id = ?
SQL

    # get user session
    my $user_session = $self->dbh->selectrow(
        <<'SQL',
            SELECT
                api_user.id AS user_id,
                api_user.name AS user_name,
                api_user.enabled AS user_enabled,
                api_user_session.hash AS user_session_hash
            FROM
                api_user,
                api_user_session
            WHERE
                api_user.id = api_user_session.user_id
                AND api_user_session.id = ?
SQL
        [ $private_token->[1] ]
    );

    # user session not found
    if ( !$user_session ) {
        $cb->( result [ 404, 'User session not found' ] );

        return;
    }

    # user disabled
    if ( !$user_session->{user_enabled} ) {
        $cb->( result [ 404, 'User disabled' ] );

        return;
    }

    # verify token
    $self->_verify_token_hash(
        $private_token->[2],
        $user_session->{user_session_hash},
        encode_utf8( $user_session->{user_id} ),
        sub ($status) {

            # token is not valid
            if ( !$status ) {
                $cb->($status);
            }

            # token is invalid
            else {
                my $auth = {
                    private_token => $private_token,

                    is_user   => 1,
                    is_root   => $user_session->{user_name} eq 'root',
                    user_id   => $user_session->{user_id},
                    user_name => $user_session->{user_name},

                    is_app          => 0,
                    app_id          => undef,
                    app_instance_id => undef,

                    permissions => {},

                    # user_id, user_session_id
                    depends_on => [ $user_session->{user_id}, $private_token->[1] ],
                };

                # get permissions
                if ( my $roles = $self->dbh->selectall( $q1, [ $source_app_instance_id, $user_session->{user_id} ] ) ) {
                    $auth->{permissions} = { map { $_->{app_role_name} => 1 } $roles->@* };
                }

                $cb->( result 200, $auth );
            }

            return;
        }
    );

    return;
}

sub create_user_session ( $self, $user_id, $cb ) {

    # get user
    $self->get_user(
        $user_id,
        sub ($user) {

            # get user error
            if ( !$user ) {
                $cb->($user);
            }

            # user is disabled
            elsif ( !$user->{data}->{enabled} ) {
                $cb->( result [ 400, q[User is disabled] ] );
            }

            # user ok
            else {

                # generate session token
                $self->_generate_token(
                    $TOKEN_TYPE_USER_SESSION,
                    $user->{data}->{id},
                    sub ($token) {

                        # token generation error
                        if ( !$token ) {
                            $cb->($token);
                        }

                        # token geneerated
                        else {
                            my $created = $self->dbh->do( q[INSERT OR IGNORE INTO api_user_session (id, user_id, created_ts, hash) VALUES (?, ?, ?, ?)], [ $token->{data}->{id}, $user->{data}->{id}, time, $token->{data}->{hash} ] );

                            if ( !$created ) {
                                $cb->( result [ 500, q[Session creation error] ] );
                            }
                            else {
                                $cb->(
                                    result 201,
                                    {   id    => $token->{data}->{id},
                                        type  => $TOKEN_TYPE_USER_SESSION,
                                        token => $token->{data}->{token},
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

    return;
}

sub remove_user_session ( $self, $user_session_id, $cb ) {
    my $removed = $self->dbh->do( q[DELETE FROM api_user_session WHERE id = ?], [$user_session_id] );

    if ($removed) {

        # fire AUTH event if user session token was removed
        P->fire_event( 'AUTH', $user_session_id );

        $cb->( result 200 );
    }
    else {
        $cb->( result [ 404, 'User session was not found' ] );
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
## |    3 | 7                    | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 7                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_auth_user_session' declared but    |
## |      |                      | not used                                                                                                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::sqlite::UserSession

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
