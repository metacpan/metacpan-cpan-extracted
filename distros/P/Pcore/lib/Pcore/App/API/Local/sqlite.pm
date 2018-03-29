package Pcore::App::API::Local::sqlite;

use Pcore -class, -result, -sql;
use Pcore::Util::UUID qw[uuid_v1mc_str];

with qw[Pcore::App::API::Local];

sub _db_add_schema_patch ( $self, $dbh ) {
    $dbh->add_schema_patch(
        1 => <<"SQL"

            -- ROLE
            CREATE TABLE IF NOT EXISTS "api_role" (
                "id" BLOB PRIMARY KEY NOT NULL DEFAULT(UUID()),
                "name" BLOB NOT NULL UNIQUE
            );

            -- USER
            CREATE TABLE IF NOT EXISTS "api_user" (
                "id" BLOB PRIMARY KEY NOT NULL DEFAULT(UUID()),
                "name" TEXT NOT NULL UNIQUE,
                "hash" BLOB NOT NULL,
                "enabled" INTEGER NOT NULL DEFAULT 0,
                "created" INTEGER NOT NULL DEFAULT(CAST(STRFTIME('%s', 'now') AS INT))
            );

            -- USER PERMISSION
            CREATE TABLE IF NOT EXISTS "api_user_permission" (
                "id" BLOB PRIMARY KEY NOT NULL DEFAULT(UUID()),
                "user_id" BLOB NOT NULL REFERENCES "api_user" ("id") ON DELETE CASCADE, -- remove role assoc., on user delete
                "role_id" BLOB NOT NULL REFERENCES "api_role" ("id") ON DELETE RESTRICT -- prevent deleting role, if has assigned users
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_uniq_api_user_permission" ON "api_user_permission" ("user_id", "role_id");

            -- USER TOKEN
            CREATE TABLE IF NOT EXISTS "api_user_token" (
                "id" BLOB PRIMARY KEY NOT NULL DEFAULT(UUID()),
                "user_id" BLOB NOT NULL REFERENCES "api_user" ("id") ON DELETE CASCADE,
                "hash" BLOB NOT NULL,
                "desc" TEXT,
                "created" INTEGER NOT NULL DEFAULT(CAST(STRFTIME('%s', 'now') AS INT))
            );

            -- USER TOKEN PERMISSION
            CREATE TABLE IF NOT EXISTS "api_user_token_permission" (
                "user_token_id" BLOB NOT NULL REFERENCES "api_user_token" ("id") ON DELETE CASCADE,
                "user_permission_id" BLOB NOT NULL REFERENCES "api_user_permission" ("id") ON DELETE CASCADE
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_uniq_api_user_token_permission" ON "api_user_token_permission" ("user_token_id", "user_permission_id");

            --- USER SESSION
            CREATE TABLE IF NOT EXISTS "api_user_session" (
                "id" BLOB PRIMARY KEY NOT NULL DEFAULT(UUID()),
                "user_id" BLOB NOT NULL REFERENCES "api_user" ("id") ON DELETE CASCADE,
                "hash" BLOB NOT NULL,
                "created" INTEGER NOT NULL DEFAULT(CAST(STRFTIME('%s', 'now') AS INT)),
                "updated" INTEGER NOT NULL DEFAULT(CAST(STRFTIME('%s', 'now') AS INT)),
                "ip" BLOB NOT NULL,
                "agent" TEXT NOT NULL
            );
SQL
    );

    return;
}

sub _db_add_roles ( $self, $dbh, $roles, $cb ) {
    $dbh->do(
        [ q[INSERT OR IGNORE INTO "api_role"], VALUES [ map { { id => uuid_v1mc_str, name => $_ } } $roles->@* ] ],
        sub ( $dbh, $res, $data ) {
            $cb->($res);

            return;
        }
    );

    return;
}

sub _db_create_user ( $self, $dbh, $user_name, $hash, $enabled, $cb ) {
    my $user_id = uuid_v1mc_str;

    $dbh->do(
        'INSERT OR IGNORE INTO "api_user" ("id", "name", "hash", "enabled") VALUES (?, ?, ?, ?)',
        [ SQL_UUID $user_id, $user_name, SQL_BYTEA $hash, SQL_BOOL $enabled ],
        sub ( $dbh, $res, $data ) {
            if ( !$res->{rows} ) {
                $cb->( result 500 );
            }
            else {
                $cb->( result 200, { id => $user_id } );
            }

            return;
        }
    );

    return;
}

sub _db_set_user_permissions ( $self, $dbh, $user_id, $roles_ids, $cb ) {
    my $modified;

    $dbh->do(
        [ 'INSERT OR IGNORE INTO "api_user_permission"', VALUES [ map { { role_id => $_, user_id => SQL_UUID $user_id } } $roles_ids->@* ] ],
        sub ( $dbh, $res, $data ) {
            $modified += $res->{rows};

            if ( !$res ) {
                $cb->( result 500 );
            }

            # remove permissions
            else {
                $dbh->do(
                    [ 'DELETE FROM "api_user_permission" WHERE "user_id" =', SQL_UUID $user_id, 'AND "role_id" NOT', IN $roles_ids ],
                    sub ( $dbh, $res, $data ) {
                        if ( !$res ) {
                            $cb->( result 500 );
                        }
                        else {
                            $modified += $res->{rows};

                            if ($modified) {
                                $cb->( result 200, { user_id => $user_id } );
                            }
                            else {
                                $cb->( result 204 );
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

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 |                      | Subroutines::ProhibitUnusedPrivateSubroutines                                                                  |
## |      | 8                    | * Private subroutine/method '_db_add_schema_patch' declared but not used                                       |
## |      | 69                   | * Private subroutine/method '_db_add_roles' declared but not used                                              |
## |      | 82                   | * Private subroutine/method '_db_create_user' declared but not used                                            |
## |      | 103                  | * Private subroutine/method '_db_set_user_permissions' declared but not used                                   |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 82, 103              | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Local::sqlite

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
