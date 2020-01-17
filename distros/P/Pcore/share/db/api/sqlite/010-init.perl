<<'SQL'

-- PERMISSIONS
CREATE TABLE "app_permission" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "name" TEXT NOT NULL UNIQUE,
    "enabled" BOOL NOT NULL DEFAULT TRUE
);

-- HASH
CREATE TABLE "auth_hash" (
    "id" UUID PRIMARY KEY NOT NULL,
    "hash" BYTEA NOT NULL
);

-- USER
CREATE TABLE "user" (
    "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "guid" UUID UNIQUE NOT NULL DEFAULT(CAST(uuid_generate_v4() AS BLOB)),
    "created" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "name" TEXT NOT NULL UNIQUE,
    "enabled" BOOL NOT NULL DEFAULT TRUE,
    "email" TEXT UNIQUE,
    "email_confirmed" BOOL NOT NULL DEFAULT FALSE,
    "gravatar" TEXT,
    "locale" TEXT,
    "telegram_name" TEXT UNIQUE
);

INSERT INTO "sqlite_sequence" ("name", "seq") VALUES ("user", 99);

CREATE TRIGGER "on_user_email_update_trigger" AFTER UPDATE ON "user"
WHEN COALESCE(OLD."email", '') != COALESCE(NEW."email", '')
BEGIN
    DELETE FROM "user_action_token" WHERE "email" = OLD."email";
    UPDATE "user" SET "email_confirmed" = FALSE, "gravatar" = MD5(LOWER(NEW."email")) WHERE "id" = NEW."id";
END;

-- USER PERMISSIONS
CREATE TABLE "user_permission" (
    "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
    "permission_id" INT2 NOT NULL REFERENCES "app_permission" ("id") ON DELETE CASCADE,
    "enabled" BOOL NOT NULL DEFAULT TRUE,
    PRIMARY KEY ("user_id", "permission_id")
);

-- USER TOKEN
CREATE TABLE "user_token" (
    "id" UUID PRIMARY KEY NOT NULL DEFAULT(CAST(uuid_generate_v4() AS BLOB)),
    "created" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "name" TEXT,
    "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
    "enabled" BOOL NOT NULL DEFAULT TRUE
);

CREATE TRIGGER "user_token_after_delete_trigger" AFTER DELETE ON "user_token"
BEGIN
    DELETE FROM "auth_hash" WHERE "id" = OLD."id";
END;

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
    "id" UUID PRIMARY KEY NOT NULL DEFAULT(CAST(uuid_generate_v4() AS BLOB)),
    "created" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE
);

CREATE TRIGGER "user_session_after_delete_trigger" AFTER DELETE ON "user_session"
BEGIN
    DELETE FROM "auth_hash" WHERE "id" = OLD."id";
END;

-- USER ACTION TOKEN
CREATE TABLE "user_action_token" (
    "id" UUID PRIMARY KEY NOT NULL DEFAULT(CAST(uuid_generate_v4() AS BLOB)),
    "user_id" INT4 NOT NULL REFERENCES "user" ("id") ON DELETE CASCADE,
    "type" INT2 NOT NULL,
    "email" TEXT NOT NULL,
    "created" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TRIGGER "user_action_token_after_delete_trigger" AFTER DELETE ON "user_action_token"
BEGIN
    DELETE FROM "auth_hash" WHERE "id" = OLD."id";
END;

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
