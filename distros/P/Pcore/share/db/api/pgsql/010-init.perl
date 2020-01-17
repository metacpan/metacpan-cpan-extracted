<<'SQL'
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
    "created" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "name" TEXT NOT NULL UNIQUE,
    "enabled" BOOLEAN NOT NULL DEFAULT TRUE,
    "email" TEXT UNIQUE,
    "email_confirmed" BOOL NOT NULL DEFAULT FALSE,
    "gravatar" TEXT,
    "locale" TEXT,
    "telegram_name" TEXT UNIQUE
);

CREATE OR REPLACE FUNCTION on_user_email_update() RETURNS TRIGGER AS $$
BEGIN
    IF COALESCE(OLD."email", '') != COALESCE(NEW."email", '') THEN
        DELETE FROM "user_action_token" WHERE "email" = OLD."email";
        UPDATE "user" SET "email_confirmed" = FALSE, "gravatar" = MD5(LOWER(NEW."email")) WHERE "id" = NEW."id";
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "on_user_email_update_trigger" AFTER UPDATE OF "email" ON "user" FOR EACH ROW EXECUTE PROCEDURE on_user_email_update();

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
    "created" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
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
    "created" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE
);

CREATE TRIGGER "user_session_after_delete_trigger" AFTER DELETE ON "user_session" FOR EACH ROW EXECUTE PROCEDURE api_delete_hash();

-- USER ACTION TOKEN
CREATE TABLE "user_action_token" (
    "id" UUID PRIMARY KEY NOT NULL DEFAULT gen_random_uuid(),
    "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
    "type" INT2 NOT NULL,
    "email" TEXT NOT NULL,
    "created" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
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
