package Pcore::App::API::Backend::Local::sqlite;

use Pcore -class, -result;

with qw[Pcore::App::API::Backend::Local::sqlite::App];
with qw[Pcore::App::API::Backend::Local::sqlite::AppInstance];
with qw[Pcore::App::API::Backend::Local::sqlite::User];
with qw[Pcore::App::API::Backend::Local::sqlite::UserToken];
with qw[Pcore::App::API::Backend::Local::sqlite::UserSession];

with qw[Pcore::App::API::Backend::Local];

# INIT DB
sub init_db ( $self, $cb ) {

    # create db
    my $dbh = $self->dbh;

    $dbh->add_schema_patch(
        1 => <<"SQL"

            --- APP
            CREATE TABLE IF NOT EXISTS "api_app" (
                "id" BLOB PRIMARY KEY NOT NULL,
                "name" BLOB NOT NULL UNIQUE,
                "desc" TEXT NOT NULL,
                "created_ts" INTEGER NOT NULL
            );

            --- APP INSTANCE
            CREATE TABLE IF NOT EXISTS "api_app_instance" (
                "id" BLOB PRIMARY KEY NOT NULL,
                "app_id" BLOB NOT NULL REFERENCES "api_app" ("id") ON DELETE RESTRICT,
                "version" BLOB NOT NULL,
                "host" BLOB NOT NULL,
                "created_ts" INTEGER NOT NULL,
                "last_connected_ts" INTEGER,
                "hash" BLOB NOT NULL
            );

            --- APP ROLE
            CREATE TABLE IF NOT EXISTS "api_app_role" (
                "id" BLOB PRIMARY KEY NOT NULL,
                "app_id" BLOB NOT NULL REFERENCES "api_app" ("id") ON DELETE CASCADE,
                "name" BLOB NOT NULL,
                "desc" TEXT NOT NULL
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_uniq_api_app_role_app_id_name" ON "api_app_role" ("app_id", "name");

            --- APP PERMISSION
            CREATE TABLE IF NOT EXISTS "api_app_permission" (
                "id" BLOB PRIMARY KEY NOT NULL,
                "app_id" BLOB NOT NULL REFERENCES "api_app" ("id") ON DELETE CASCADE, --- remove role assoc., on app delete
                "app_role_id" BLOB NOT NULL REFERENCES "api_app_role" ("id") ON DELETE RESTRICT, --- prevent deleting role, if has assigned apps
                "approved" INTEGER NOT NULL DEFAULT 0
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_uniq_api_app_permission" ON "api_app_permission" ("app_id", "app_role_id");

            --- USER
            CREATE TABLE IF NOT EXISTS "api_user" (
                "id" BLOB PRIMARY KEY NOT NULL,
                "name" TEXT NOT NULL UNIQUE,
                "created_ts" INTEGER,
                "enabled" INTEGER NOT NULL DEFAULT 0,
                "hash" BLOB NOT NULL
            );

            --- USER PERMISSION
            CREATE TABLE IF NOT EXISTS "api_user_permission" (
                "id" BLOB PRIMARY KEY NOT NULL,
                "user_id" BLOB NOT NULL REFERENCES "api_user" ("id") ON DELETE CASCADE, --- remove role assoc., on user delete
                "app_role_id" BLOB NOT NULL REFERENCES "api_app_role" ("id") ON DELETE RESTRICT --- prevent deleting role, if has assigned users
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_uniq_api_user_permission" ON "api_user_permission" ("user_id", "app_role_id");

            --- USER TOKEN
            CREATE TABLE IF NOT EXISTS "api_user_token" (
                "id" BLOB PRIMARY KEY NOT NULL, --- UUID hex
                "user_id" BLOB NOT NULL REFERENCES "api_user" ("id") ON DELETE CASCADE,
                "desc" TEXT,
                "created_ts" INTEGER,
                "hash" BLOB NOT NULL
            );

            --- USER TOKEN PERMISSION
            CREATE TABLE IF NOT EXISTS "api_user_token_permission" (
                "id" BLOB PRIMARY KEY NOT NULL,
                "user_token_id" BLOB NOT NULL REFERENCES "api_user_token" ("id") ON DELETE CASCADE,
                "user_permission_id" BLOB NOT NULL REFERENCES "api_user_permission" ("id") ON DELETE CASCADE
            );

            CREATE UNIQUE INDEX IF NOT EXISTS "idx_uniq_api_user_token_permission" ON "api_user_token_permission" ("user_token_id", "user_permission_id");

            --- USER SESSION
            CREATE TABLE IF NOT EXISTS "api_user_session" (
                "id" BLOB PRIMARY KEY NOT NULL, --- UUID hex
                "user_id" BLOB NOT NULL REFERENCES "api_user" ("id") ON DELETE CASCADE,
                "created_ts" INTEGER,
                "hash" BLOB NOT NULL
            );
SQL
    );

    $dbh->upgrade_schema( sub ($status) {
        die $status if !$status;

        $cb->($status);

        return;
    } );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::sqlite

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
