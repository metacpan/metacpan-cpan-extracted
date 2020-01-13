package Pcore::App::API::Backend::Local::User;

use Pcore -role, -sql, -res;
use Pcore::App::API qw[:ROOT_USER :PRIVATE_TOKEN :INVALIDATE_TYPE];

sub _user_password_authenticate ( $self, $private_token ) {

    # get user
    state $q1 = $self->{dbh}->prepare(q[SELECT "user"."id", "user"."enabled", "auth_hash"."hash" FROM "user" LEFT JOIN "auth_hash" ON ("user"."guid" = "auth_hash"."id") WHERE "user"."name" = ?]);

    my $user = $self->{dbh}->selectrow( $q1, [ $private_token->[$PRIVATE_TOKEN_ID] ] );

    # user not found
    return res [ 404, 'User not found' ] if !$user->{data};

    # user is disabled
    return res [ 404, 'User is disabled' ] if !$user->{data}->{enabled};

    # verify token
    my $status = $self->_verify_private_token( $private_token, $user->{data}->{hash} );

    # token is invalid
    return $status if !$status;

    # token is valid
    return $self->_return_auth( $private_token, $user->{data}->{id}, $private_token->[$PRIVATE_TOKEN_ID] );
}

sub user_create ( $self, $user_name, $password, $enabled, $permissions ) {

    # validate user name
    return res [ 400, 'User name is not valid' ] if !$self->validate_user_name($user_name);

    # lowercase user name
    $user_name = lc $user_name;

    # get dbh
    my ( $res, $dbh ) = $self->{dbh}->get_dbh;

    # unable to get dbh
    return $res if !$res;

    # start transaction
    $res = $dbh->begin_work;

    # failed to start transaction
    return $res if !$res;

    $enabled = !!$enabled;

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

    $res = $self->_db_insert_user( $dbh, $user_name );

    # dbh error
    return $on_finish->( $dbh, $res ) if !$res;

    my $user_id = $res->{data}->{id};
    my $guid    = $res->{data}->{guid};

    # generate random password if password is empty
    $password = P->random->bytes(32) if !defined $password || $password eq $EMPTY;

    # generate user password hash
    $res = $self->_generate_password_hash( $user_name, $password );

    # error generating hash
    return $on_finish->( $dbh, $res ) if !$res;

    # insert hash
    state $q21 = $dbh->prepare(q[INSERT INTO "auth_hash" ("id", "hash") VALUES (?, ?)]);

    $res = $dbh->do( $q21, [ $guid, SQL_BYTEA $res->{data}->{hash} ] );

    # dbh error
    return $on_finish->( $dbh, $res ) if !$res;

    # update user
    state $q2 = $dbh->prepare(q[UPDATE "user" SET "enabled" = ? WHERE "id" = ?]);

    $res = $dbh->do( $q2, [ SQL_BOOL $enabled, $user_id ] );

    # dbh error
    return $on_finish->( $dbh, $res ) if !$res;

    # set user permissions
    $res = $self->user_set_permissions( $user_id, $permissions, $dbh );

    return $on_finish->( $dbh, $res ) if !$res;

    return $on_finish->(
        $dbh,
        res 200,
        {   id      => $user_id,
            name    => $user_name,
            enabled => $enabled,
        }
    );
}

sub user_set_password ( $self, $user_id, $password, $dbh = undef ) {
    return res [ 400, q[Passwort can't be empty] ] if !defined $password || $password eq $EMPTY;

    $dbh //= $self->{dbh};

    # resolve user
    my $user = $self->_db_get_user( $dbh, $user_id );

    # dbh error
    return $user if !$user;

    my $password_hash = $self->_generate_password_hash( $user->{data}->{name}, $password );

    # password hash genereation error
    return $password_hash if !$password_hash;

    # password hash generated
    state $q1 = $dbh->prepare(q[UPDATE "auth_hash" SET "hash" = ? WHERE "id" = ?]);

    my $res = $dbh->do( $q1, [ SQL_BYTEA $password_hash->{data}->{hash}, $user->{data}->{guid} ] );

    return res 500 if !$res->{rows};

    # fire AUTH event if user password was changed
    P->fire_event( 'app.api.auth.invalidate', { type => $INVALIDATE_TOKEN, id => $user->{data}->{name} } );

    return res 200;
}

sub user_set_enabled ( $self, $user_id, $enabled ) {
    return res [ 400, qw[Can't modify root user] ] if $self->user_is_root($user_id);

    my $dbh = $self->{dbh};

    # root can't be disabled
    state $q1 = $dbh->prepare(q[UPDATE "user" SET "enabled" = ? WHERE "id" = ? AND "enabled" = ?]);

    $enabled = 0+ !!$enabled;

    my $res = $dbh->do(
        $q1,
        [    #
            SQL_BOOL $enabled,
            $user_id,
            SQL_BOOL !$enabled,
        ]
    );

    # dbh error
    return $res if !$res;

    # modified
    if ( $res->{rows} ) {
        P->fire_event( 'app.api.auth.invalidate', { type => $INVALIDATE_USER, id => $user_id } );

        return res 200;
    }

    # not modified
    else {
        return res 204;
    }
}

sub user_get_permissions ( $self, $user_id, $dbh = undef ) {
    $dbh //= $self->{dbh};

    state $q1 = $dbh->prepare(
        <<'SQL',
        SELECT
            "app_permission"."name",
            CASE
                WHEN "user"."id" = ? THEN TRUE
                ELSE COALESCE("user_permission"."enabled", FALSE)
            END  AS "enabled"
        FROM
            "app_permission"
            LEFT JOIN "user" ON (
                "user"."id" = ?
            )
            LEFT JOIN "user_permission" ON (
                "user_permission"."permission_id" = "app_permission"."id"
                AND "user_permission"."user_id" = "user"."id"
            )
        WHERE
            "app_permission"."enabled" = TRUE
SQL
    );

    my $res = $dbh->selectall( $q1, [ $ROOT_USER_ID, $user_id ] );

    # dbh error
    return $res if !$res;

    return res 200, { map { $_->{name} => $_->{enabled} } $res->{data}->@* };
}

sub user_set_permissions ( $self, $user_id, $permissions, $dbh = undef ) {
    return res 204 if !$permissions || !$permissions->%*;    # not modified

    return res [ 400, qw[Can't modify root user] ] if $self->user_is_root($user_id);

    my $on_finish;

    if ( !defined $dbh ) {

        # get dbh
        ( my $res, $dbh ) = $self->{dbh}->get_dbh;

        # unable to get dbh
        return $res if !$res;

        # start transaction
        $res = $dbh->begin_work;

        # failed to start transaction
        return $res if !$res;

        $on_finish = sub ( $dbh, $res ) {
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
    }
    else {
        $on_finish = sub ( $dbh, $res ) { return $res };
    }

    my $res;
    my $modified = 0;

    while ( my ( $name, $enabled ) = each $permissions->%* ) {
        $enabled = 0+ !!$enabled;

        state $q1 = $dbh->prepare(
            <<'SQL'
            INSERT INTO "user_permission" (
                "user_id",
                "permission_id",
                "enabled"
            )
            VALUES (
                ?,
                (SELECT "id" FROM "app_permission" WHERE "name" = ?),
                ?
            )
            ON CONFLICT DO NOTHING
SQL
        );

        $res = $dbh->do( $q1, [ $user_id, $name, SQL_BOOL $enabled] );

        # dbh error
        return $on_finish->( $dbh, $res ) if !$res;

        # permission inserted
        if ( $res->{rows} ) {
            $modified = 1;
        }

        # permission is already exists
        else {
            state $q2 = $dbh->prepare(
                <<'SQL'
                UPDATE
                    "user_permission"
                SET
                    "enabled" = ?
                WHERE
                    "user_id" = ?
                    AND "enabled" = ?
                    AND "permission_id" = (SELECT "id" FROM "app_permission" WHERE "name" = ?)
SQL
            );

            $res = $dbh->do( $q2, [ SQL_BOOL $enabled, $user_id, SQL_BOOL !$enabled, $name ] );

            # dbh error
            return $on_finish->( $dbh, $res ) if !$res;

            # permission updated
            $modified = 1 if $res->{rows};
        }
    }

    if ($modified) {

        # commit
        $res = $on_finish->( $dbh, res 200 );

        # permissions was modified, fire event if commit was ok
        P->fire_event( 'app.api.auth.invalidate', { type => $INVALIDATE_USER, id => $user_id } ) if $res;

        return $res;
    }
    else {
        return $on_finish->( $dbh, res 204 );
    }
}

# UTIL
sub _db_get_user ( $self, $dbh, $user_id ) {
    state $q1 = $dbh->prepare('SELECT "id", "guid", "name" FROM "user" WHERE "id" = ? AND "enabled" = TRUE');

    my $user = $dbh->selectrow( $q1, [$user_id] );

    # dbh error
    return $user if !$user;

    # user was not found or disabled
    return res 404 if !$user->{data};

    return $user;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 6                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_user_password_authenticate'        |
## |      |                      | declared but not used                                                                                          |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 29                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::User

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
