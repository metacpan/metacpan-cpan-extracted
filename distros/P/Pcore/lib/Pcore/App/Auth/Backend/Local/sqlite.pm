package Pcore::App::Auth::Backend::Local::sqlite;

use Pcore -class, -res, -sql;

with qw[Pcore::App::Auth::Backend::Local];

sub _db_add_schema_patch ( $self, $dbh ) {
    $dbh->add_schema_patch(
        1, 'auth', <<"SQL"

            -- PERMISSIONS
            CREATE TABLE IF NOT EXISTS "auth_app_permission" (
                "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                "name" TEXT NOT NULL UNIQUE,
                "enabled" BOOL NOT NULL DEFAULT TRUE
            );

            -- USER
            CREATE TABLE IF NOT EXISTS "auth_user" (
                "id" UUID PRIMARY KEY NOT NULL DEFAULT(CAST(uuid_generate_v4() AS BLOB)),
                "created" INT8 NOT NULL DEFAULT(STRFTIME('%s', 'NOW')),
                "name" TEXT NOT NULL UNIQUE,
                "hash" BYTEA NOT NULL,
                "enabled" BOOL NOT NULL DEFAULT TRUE
            );

            -- USER PERMISSION
            CREATE TABLE IF NOT EXISTS "auth_user_permission" (
                "user_id" UUID NOT NULL REFERENCES "auth_user" ("id") ON DELETE CASCADE,
                "permission_id" INT2 NOT NULL REFERENCES "auth_app_permission" ("id") ON DELETE CASCADE,
                "enabled" BOOL NOT NULL DEFAULT TRUE,
                PRIMARY KEY ("user_id", "permission_id")
            );

            -- USER TOKEN
            CREATE TABLE IF NOT EXISTS "auth_token" (
                "id" UUID PRIMARY KEY NOT NULL DEFAULT(CAST(uuid_generate_v4() AS BLOB)),
                "created" INT8 NOT NULL DEFAULT(STRFTIME('%s', 'NOW')),
                "name" TEXT,
                "type" INT2 NOT NULL,
                "user_id" UUID NOT NULL REFERENCES "auth_user" ("id") ON DELETE CASCADE,
                "hash" BYTEA NOT NULL,
                "enabled" BOOL NOT NULL DEFAULT TRUE
            );

            -- USER TOKEN PERMISSION
            CREATE TABLE IF NOT EXISTS "auth_token_permission" (
                "token_id" UUID NOT NULL,
                "user_id" UUID NOT NULL,
                "permission_id" INT2 NOT NULL,
                "enabled" BOOL NOT NULL DEFAULT TRUE,
                PRIMARY KEY ("token_id", "permission_id"),
                FOREIGN KEY ("user_id", "permission_id") REFERENCES "auth_user_permission" ("user_id", "permission_id") ON DELETE CASCADE,
                FOREIGN KEY ("permission_id") REFERENCES "auth_app_permission" ("id") ON DELETE CASCADE
            );
SQL
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
## |    3 | 7                    | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_db_add_schema_patch' declared but  |
## |      |                      | not used                                                                                                       |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::Auth::Backend::Local::sqlite

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
