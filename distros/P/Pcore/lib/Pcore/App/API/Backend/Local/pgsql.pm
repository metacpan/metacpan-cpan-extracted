package Pcore::App::API::Backend::Local::pgsql;

use Pcore -class, -sql, -res;
use Pcore::App::API qw[:ROOT_USER];

with qw[Pcore::App::API::Backend::Local];

sub _db_add_schema_patch ( $self, $dbh ) {
    $dbh->add_schema_patch(
        1, 'api', <<'SQL'
            CREATE EXTENSION IF NOT EXISTS "pgcrypto";

            -- PERMISSIONS
            CREATE TABLE "app_permission" (
                "id" SERIAL2 PRIMARY KEY NOT NULL,
                "name" TEXT NOT NULL UNIQUE,
                "enabled" BOOL NOT NULL DEFAULT TRUE
            );

            -- HASH
            CREATE TABLE "auth_hash" (
                "id" UUID PRIMARY KEY NOT NULL,
                "hash" BYTEA NOT NULL
            );

            -- USER
            CREATE SEQUENCE "user_id_seq" AS INT4 INCREMENT BY 1 START 100;

            CREATE TABLE "user" (
                "id" INT4 PRIMARY KEY NOT NULL DEFAULT NEXTVAL('user_id_seq'),
                "guid" UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
                "created" INT8 NOT NULL DEFAULT EXTRACT(EPOCH FROM CURRENT_TIMESTAMP),
                "name" TEXT NOT NULL UNIQUE,
                "enabled" BOOLEAN NOT NULL DEFAULT TRUE,
                "email" TEXT UNIQUE,
                "email_confirmed" BOOL NOT NULL DEFAULT FALSE,
                "avatar" TEXT,
                "locale" TEXT,
                "telegram_name" TEXT UNIQUE
            );

            CREATE OR REPLACE FUNCTION on_user_email_update() RETURNS TRIGGER AS $$
            BEGIN
                IF OLD."email" != NEW."email" OR NEW."email" IS NULL THEN
                    DELETE FROM "user_action_token" WHERE "email" = OLD."email";
                    UPDATE "user" SET "email_confirmed" = FALSE WHERE "id" = NEW."id";
                END IF;

                RETURN NULL;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TRIGGER "on_uer_email_update_trigger" AFTER UPDATE OF "email" ON "user" FOR EACH ROW EXECUTE PROCEDURE on_user_email_update();

            -- USER PERMISSIONS
            CREATE TABLE "user_permission" (
                "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
                "permission_id" INT2 NOT NULL REFERENCES "app_permission" ("id") ON DELETE CASCADE,
                "enabled" BOOL NOT NULL DEFAULT TRUE,
                PRIMARY KEY ("user_id", "permission_id")
            );

            -- USER TOKEN
            CREATE TABLE "user_token" (
                "id" UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
                "created" INT8 NOT NULL DEFAULT EXTRACT(EPOCH FROM CURRENT_TIMESTAMP),
                "name" TEXT,
                "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
                "enabled" BOOL NOT NULL DEFAULT TRUE
            );

            CREATE FUNCTION api_delete_hash() RETURNS TRIGGER AS $$
            BEGIN
                DELETE FROM "auth_hash" WHERE "id" = OLD."id";

                RETURN NULL;
            END;
            $$ LANGUAGE plpgsql;

            CREATE TRIGGER "user_token_after_delete_trigger" AFTER DELETE ON "user_token" FOR EACH ROW EXECUTE PROCEDURE api_delete_hash();

            -- USER TOKEN PERMISSIONS
            CREATE TABLE "user_token_permission" (
                "token_id" UUID NOT NULL,
                "user_id" INT4 NOT NULL,
                "permission_id" INT2 NOT NULL,
                "enabled" BOOL NOT NULL DEFAULT TRUE,
                PRIMARY KEY ("token_id", "permission_id"),
                FOREIGN KEY ("user_id", "permission_id") REFERENCES "user_permission" ("user_id", "permission_id") ON DELETE CASCADE,
                FOREIGN KEY ("permission_id") REFERENCES "app_permission" ("id") ON DELETE CASCADE
            );

            -- USER SESSION
            CREATE TABLE "user_session" (
                "id" UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
                "created" INT8 NOT NULL DEFAULT EXTRACT(EPOCH FROM CURRENT_TIMESTAMP),
                "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE
            );

            CREATE TRIGGER "user_session_after_delete_trigger" AFTER DELETE ON "user_session" FOR EACH ROW EXECUTE PROCEDURE api_delete_hash();

            -- USER ACTION TOKEN
            CREATE TABLE "user_action_token" (
                "id" UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
                "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
                "type" INT2 NOT NULL,
                "email" TEXT NOT NULL,
                "created" INT8 NOT NULL DEFAULT EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)
            );

            CREATE TRIGGER "user_action_token_after_delete_trigger" AFTER DELETE ON "user_action_token" FOR EACH ROW EXECUTE PROCEDURE api_delete_hash();

            -- SETTINGS
            CREATE TABLE "settings" (
                "id" INT2 PRIMARY KEY NOT NULL DEFAULT 1,

                -- DOMAIN
                "domain" TEXT,

                -- SMTP
                "smtp_host" TEXT,
                "smtp_port" INT2,
                "smtp_username" TEXT,
                "smtp_password" TEXT,
                "smtp_tls" BOOL NOT NULL DEFAULT TRUE,

                -- TELEGRAM
                "telegram_bot_name" TEXT,
                "telegram_bot_key" TEXT,
                "telegram_bot_enabled" BOOL NOT NULL DEFAULT FALSE,
                "telegram_signin_enabled" BOOL NOT NULL DEFAULT FALSE
            );

            INSERT INTO "settings" ("smtp_host", "smtp_port", "smtp_tls") VALUES ('smtp.gmail.com', 465, TRUE);
SQL
    );

    return;
}

sub _db_insert_user ( $self, $dbh, $user_name ) {
    my $res;

    if ( $self->user_is_root($user_name) ) {
        state $q1 = $dbh->prepare(q[INSERT INTO "user" ("id", "name", "enabled") VALUES (?, ?, FALSE) ON CONFLICT DO NOTHING RETURNING "id", "guid"]);

        # insert user
        $res = $dbh->selectrow( $q1, [ $ROOT_USER_ID, $user_name ] );
    }
    else {
        state $q1 = $dbh->prepare(q[INSERT INTO "user" ("name", "enabled") VALUES (?, FALSE) ON CONFLICT DO NOTHING RETURNING "id", "guid"]);

        # insert user
        $res = $dbh->selectrow( $q1, [$user_name] );
    }

    # dbh error
    return $res if !$res;

    # username already exists
    return res [ 400, 'Username is already exists' ] if !$res->{data};

    return $res;
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
## |      | 141                  | * Private subroutine/method '_db_insert_user' declared but not used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::App::API::Backend::Local::pgsql

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
