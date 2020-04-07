package Pcore::App::API::Backend::Local::UserSession;

use Pcore -role, -sql, -res;
use Pcore::App::API::Const qw[:ROOT_USER :PRIVATE_TOKEN :INVALIDATE_TYPE :TOKEN_TYPE];

sub _user_session_authenticate ( $self, $private_token ) {

    # get user token
    state $q1 = $self->{dbh}->prepare(
        <<'SQL'
            SELECT
                "user"."id" AS "user_id",
                "user"."name" AS "user_name",
                "auth_hash"."hash" AS "hash"
            FROM
                "user",
                "user_session",
                "auth_hash"
            WHERE
                "user"."id" = "user_session"."user_id"
                AND "user_session"."id" = "auth_hash"."id"
                AND "user"."enabled" = TRUE
                AND "user_session"."id" = ?
SQL
    );

    my $token = $self->{dbh}->selectrow( $q1, [ SQL_UUID $private_token->[$PRIVATE_TOKEN_ID] ] );

    # dbh error
    return $token if !$token;

    # token was not found or user is disabled
    return res 404 if !$token->{data};

    $token = $token->{data};

    # verify token, token is not valid
    return res [ 400, 'Invalid token' ] if !$self->_verify_private_token( $private_token, $token->{hash} );

    # token is valid
    return $self->_return_auth( $private_token, $token->{user_id}, $token->{user_name} );
}

sub user_session_create ( $self, $user_id ) {
    my ( $res, $dbh ) = $self->{dbh}->get_dbh;

    # unable to get dbh
    return $res if !$res;

    # resolve user
    my $user = $self->_db_get_user( $dbh, $user_id );

    # user wasn't found
    return $user if !$user;

    # generate session token
    my $token = $self->_generate_token($TOKEN_TYPE_SESSION);

    # token generation error
    return $token if !$token;

    state $on_finish = sub ( $dbh, $res ) {
        if ( !$res ) {
            my $res1 = $dbh->rollback;
        }
        else {
            my $res1 = $dbh->commit;

            # error committing transaction
            return $res1 if !$res1;
        }

        return $res;
    };

    # start transaction
    $res = $dbh->begin_work;

    # failed to start transaction
    return $res if !$res;

    # store token hash
    state $q1 = $dbh->prepare('INSERT INTO "auth_hash" ("id", "hash") VALUES (?, ?)');

    $res = $dbh->do( $q1, [ SQL_UUID $token->{data}->{id}, SQL_BYTEA $token->{data}->{hash} ] );

    # dbh error
    return $on_finish->( $dbh, $res ) if !$res;

    # store token
    state $q2 = $dbh->prepare('INSERT INTO "user_session" ("id", "user_id") VALUES (?, ?)');

    $res = $dbh->do( $q2, [ SQL_UUID $token->{data}->{id}, $user->{data}->{id} ] );

    # dbh error
    return $on_finish->( $dbh, $res ) if !$res;

    my $permissions = $self->user_get_permissions( $user->{data}->{id}, $dbh );

    # get permissions error
    return $on_finish->( $dbh, $permissions ) if !$permissions;

    return $on_finish->(
        $dbh,
        res 200,
        {   id          => $token->{data}->{id},
            type        => $TOKEN_TYPE_SESSION,
            token       => $token->{data}->{token},
            user_id     => $user->{data}->{id},
            user_name   => $user->{data}->{name},
            permissions => $permissions->{data},
        }
    );
}

sub user_session_remove ( $self, $token_id ) {
    state $q1 = $self->{dbh}->prepare('DELETE FROM "user_session" WHERE "id" = ?');

    my $res = $self->{dbh}->do( $q1, [ SQL_UUID $token_id ] );

    # dbh error
    return $res if !$res;

    # not found
    return res 204 if !$res->{rows};

    P->fire_event( 'app.api.auth.invalidate', { type => $INVALIDATE_TOKEN, id => $token_id } );

    return res 200;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 6                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_user_session_authenticate'         |
## |      |                      | declared but not used                                                                                          |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::UserSession

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
