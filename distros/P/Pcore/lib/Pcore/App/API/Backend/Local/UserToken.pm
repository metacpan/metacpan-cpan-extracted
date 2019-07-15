package Pcore::App::API::Backend::Local::UserToken;

use Pcore -role, -sql, -res;
use Pcore::App::API qw[:ROOT_USER :PRIVATE_TOKEN :INVALIDATE_TYPE :TOKEN_TYPE];
use Pcore::Lib::Digest qw[sha3_512];

sub _user_token_authenticate ( $self, $private_token ) {

    # get user token
    state $q1 = $self->{dbh}->prepare(
        <<'SQL'
            SELECT
                "user"."id" AS "user_id",
                "user"."name" AS "user_name",
                "auth_hash"."hash" AS "hash"
            FROM
                "user",
                "user_token",
                "auth_hash"
            WHERE
                "user"."id" = "user_token"."user_id"
                AND "user_token"."id" = "auth_hash"."id"
                AND "user_token"."id" = ?
                AND "user_token"."enabled" = TRUE
                AND "user"."enabled" = TRUE
SQL
    );

    my $token = $self->{dbh}->selectrow( $q1, [ SQL_UUID $private_token->[$PRIVATE_TOKEN_ID] ] );

    # dbh error
    return $token if !$token;

    # user or token is disabled or token was not found
    return res 404 if !$token->{data};

    $token = $token->{data};

    # verify token, token is not valid
    return res [ 400, 'Invalid token' ] if !$self->_verify_private_token( $private_token, $token->{hash} );

    # token is valid
    return $self->_return_auth( $private_token, $token->{user_id}, $token->{user_name} );
}

sub user_token_create ( $self, $user_id, $name, $enabled, $permissions ) {

    # get dbh
    my ( $res, $dbh ) = $self->{dbh}->get_dbh;

    # unable to get dbh
    return $res if !$res;

    # resolve user
    my $user = $self->_db_get_user( $dbh, $user_id );

    # user wasn't found
    return $user if !$user;

    # generate user token
    my $token = $self->_generate_token($TOKEN_TYPE_TOKEN);

    # token generation error
    return $token if !$token;

    # start transaction
    $res = $dbh->begin_work;

    # failed to start transaction
    return $res if !$res;

    state $on_finish = sub ( $dbh, $res ) {
        if ( !$res ) {
            my $res1 = $dbh->rollback;
        }
        else {
            my $res1 = $dbh->commit;

            # commit error
            return $res1 if !$res1;
        }

        return $res;
    };

    # insert token hash
    state $q1 = $dbh->prepare('INSERT INTO "auth_hash" ("id", "hash" ) VALUES (?, ?)');

    $res = $dbh->do( $q1, [ SQL_UUID $token->{data}->{id}, SQL_BYTEA $token->{data}->{hash} ] );

    return $on_finish->( $dbh, $res ) if !$res;

    # insert token
    state $q2 = $dbh->prepare('INSERT INTO "user_token" ("id", "user_id", "name", "enabled" ) VALUES (?, ?, ?, ?)');

    $enabled = 0+ !!$enabled;

    $res = $dbh->do( $q2, [ SQL_UUID $token->{data}->{id}, $user->{data}->{id}, $name, SQL_BOOL $enabled ] );

    return $on_finish->( $dbh, $res ) if !$res;

    # set token permissions
    $res = $self->user_token_set_permissions( $token->{data}->{id}, $permissions, $dbh );

    return $on_finish->( $dbh, $res ) if !$res;

    # get token permissions
    my $token_permissions = $self->user_token_get_permissions( $token->{data}->{id}, $dbh );

    return $on_finish->( $dbh, $token_permissions ) if !$token_permissions;

    return $on_finish->(
        $dbh,
        res 200,
        {   id          => $token->{data}->{id},
            type        => $TOKEN_TYPE_TOKEN,
            user_id     => $user->{data}->{id},
            user_name   => $user->{data}->{name},
            token       => $token->{data}->{token},
            name        => $name,
            enabled     => $enabled,
            permissions => $token_permissions->{data},
        }
    );
}

sub user_token_remove ( $self, $token_id ) {
    state $q1 = $self->{dbh}->prepare('DELETE FROM "user_token" WHERE "id" = ?');

    my $res = $self->{dbh}->do( $q1, [ SQL_UUID $token_id ] );

    # dbh error
    return $res if !$res;

    # not found
    return res 204 if !$res->{rows};

    P->fire_event( 'app.api.auth.invalidate', { type => $INVALIDATE_TOKEN, id => $token_id } );

    return res 200;
}

sub user_token_set_enabled ( $self, $token_id, $enabled ) {
    my $dbh = $self->{dbh};

    state $q1 = $dbh->prepare(q[UPDATE "user_token" SET "enabled" = ? WHERE "id" = ? AND "enabled" = ?]);

    $enabled = 0+ !!$enabled;

    my $res = $dbh->do( $q1, [ SQL_BOOL $enabled, SQL_UUID $token_id, SQL_BOOL !$enabled ] );

    # dbh error
    return $res if !$res;

    # modified
    if ( $res->{rows} ) {
        P->fire_event( 'app.api.auth.invalidate', { type => $INVALIDATE_TOKEN, id => $token_id } );

        return res 200;
    }

    # not modified
    else {
        return res 204;
    }
}

sub user_token_get_permissions ( $self, $token_id, $dbh = undef ) {
    $dbh //= $self->{dbh};

    state $q1 = $dbh->prepare(
        <<'SQL',
        SELECT
            "app_permission"."name",
            COALESCE("user_permission"."enabled" AND "user_token_permission"."enabled", FALSE) AS "enabled"
        FROM
            "app_permission"
            CROSS JOIN (SELECT "user_id", "id" FROM "user_token" WHERE "id" = ?) AS "user_token"
            LEFT JOIN "user_token_permission" ON (
                "user_token_permission"."permission_id" = "app_permission"."id"
                AND "user_token_permission"."token_id" = "user_token"."id"
            )
            LEFT JOIN "user_permission" ON (
                "user_permission"."user_id" = "user_token"."user_id"
                AND "user_permission"."permission_id" = "app_permission"."id"
            )
        WHERE
            "app_permission"."enabled" = TRUE
SQL
    );

    my $res = $dbh->selectall( $q1, [ SQL_UUID $token_id ], );

    # dbh error
    return $res if !$res;

    return res 200, { map { $_->{name} => $_->{enabled} } $res->{data}->@* };
}

sub user_token_get_permissions_for_edit ( $self, $token_id, $dbh = undef ) {
    $dbh //= $self->{dbh};

    state $q1 = $dbh->prepare(
        <<'SQL',
        SELECT
            "app_permission"."name",
            COALESCE("user_token_permission"."enabled", FALSE) AS "token_enabled",
            CASE
                WHEN "user_token"."user_id" = ? THEN TRUE
                ELSE COALESCE("user_permission"."enabled", FALSE)
            END AS "user_enabled",
            CASE
                WHEN "user_token"."user_id" = ? THEN COALESCE("user_token_permission"."enabled", FALSE)
                ELSE COALESCE("user_permission"."enabled" AND "user_token_permission"."enabled", FALSE)
            END AS "enabled",
            CASE
                WHEN "user_token"."user_id" = ? THEN TRUE
                WHEN NOT "user_permission"."enabled" THEN FALSE
                ELSE TRUE
            END  AS "can_edit",
            CASE
                WHEN "user_permission"."enabled" IS NULL THEN FALSE
                ELSE TRUE
            END  AS "has_user_permission",
            CASE
                WHEN "user_token_permission"."enabled" IS NULL THEN FALSE
                ELSE TRUE
            END  AS "has_token_permission"
        FROM
            "app_permission"
            CROSS JOIN (SELECT "user_id", "id" FROM "user_token" WHERE "id" = ?) AS "user_token"
            LEFT JOIN "user_token_permission" ON (
                "user_token_permission"."permission_id" = "app_permission"."id"
                AND "user_token_permission"."token_id" = "user_token"."id"
            )
            LEFT JOIN "user_permission" ON (
                "user_permission"."user_id" = "user_token"."user_id"
                AND "user_permission"."permission_id" = "app_permission"."id"
            )
        WHERE
            "app_permission"."enabled" = TRUE
        ORDER BY "name" ASC
SQL
    );

    my $res = $dbh->selectall(
        $q1,
        [   $ROOT_USER_ID,    #
            $ROOT_USER_ID,
            $ROOT_USER_ID,
            SQL_UUID $token_id,
        ],
    );

    # dbh error
    return $res if !$res;

    return res 200, $res->{data};
}

sub user_token_set_permissions ( $self, $token_id, $permissions, $dbh = undef ) {
    return res 204 if !$permissions || !$permissions->%*;    # not modified

    my $token_permissions = $self->user_token_get_permissions_for_edit( $token_id, $dbh );

    return $token_permissions if !$token_permissions;

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

    $token_permissions = { map { $_->{name} => $_ } $token_permissions->{data}->@* };

    my ( $modified, $insert_user_permission, $insert_token_permission, $update_token_permission );

    while ( my ( $name, $enabled ) = each $permissions->%* ) {
        $enabled = 0+ !!$enabled;

        # can not edit permission
        if ( !$token_permissions->{$name}->{can_edit} ) {
            return $on_finish->( $dbh, res [ 400, q[Unable to set token permissions] ] );
        }

        # need to modify permission
        elsif ( $enabled != $token_permissions->{$name}->{enabled} ) {
            $modified = 1;

            if ( !$token_permissions->{$name}->{has_user_permission} ) {
                push $insert_user_permission->@*,
                  { user_id       => SQL [ '(SELECT "user_id" FROM "user_token" WHERE "id" =', SQL_UUID $token_id, ')' ],
                    permission_id => SQL [ '(SELECT "id" FROM "app_permission" WHERE "name" =', \$name, ')' ],
                    enabled       => SQL_BOOL 1,
                  };
            }

            if ( !$token_permissions->{$name}->{has_token_permission} ) {
                push $insert_token_permission->@*,
                  { user_id       => SQL [ '(SELECT "user_id" FROM "user_token" WHERE "id" =', SQL_UUID $token_id, ')' ],
                    token_id      => SQL_UUID $token_id,
                    permission_id => SQL [ '(SELECT "id" FROM "app_permission" WHERE "name" =', \$name, ')' ],
                    enabled       => SQL_BOOL $enabled,
                  };
            }
            else {
                push $update_token_permission->@*, [ SQL_BOOL $enabled, SQL_UUID $token_id, $name, ];
            }
        }
    }

    if ($insert_user_permission) {
        my $res = $dbh->do( [ 'INSERT INTO "user_permission"', VALUES $insert_user_permission] );

        return $on_finish->( $dbh, $res ) if !$res;

        return $on_finish->( $dbh, res 500 ) if !$res->{rows};
    }

    if ($insert_token_permission) {
        my $res = $dbh->do( [ 'INSERT INTO "user_token_permission"', VALUES $insert_token_permission] );

        return $on_finish->( $dbh, $res ) if !$res;

        return $on_finish->( $dbh, res 500 ) if !$res->{rows};
    }

    if ($update_token_permission) {
        state $q1 = $dbh->prepare(q[UPDATE "user_token_permission" SET "enabled" = ? WHERE "token_id" = ? AND "permission_id" = (SELECT "id" FROM "app_permission" WHERE "name" = ?)]);

        for my $bind ( $update_token_permission->@* ) {
            my $res = $dbh->do( $q1, $bind );

            return $on_finish->( $dbh, $res ) if !$res;

            return $on_finish->( $dbh, res 500 ) if !$res->{rows};
        }
    }

    if ($modified) {
        my $res = $on_finish->( $dbh, res 200 );

        # permissions was modified, fire event if commit was ok
        P->fire_event( 'app.api.auth.invalidate', { type => $INVALIDATE_TOKEN, id => $token_id } );

        return $res;
    }
    else {
        return $on_finish->( $dbh, res 204 );
    }
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 7                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_user_token_authenticate' declared  |
## |      |                      | but not used                                                                                                   |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 46                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 261                  | Subroutines::ProhibitExcessComplexity - Subroutine "user_token_set_permissions" with high complexity score     |
## |      |                      | (29)                                                                                                           |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::UserToken

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
