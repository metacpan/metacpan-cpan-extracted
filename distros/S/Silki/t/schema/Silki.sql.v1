SET CLIENT_MIN_MESSAGES = ERROR;

CREATE LANGUAGE plpgsql;

CREATE DOMAIN email_address AS VARCHAR(255)
       CONSTRAINT valid_email_address CHECK ( VALUE ~ E'^.+@.+(?:\\..+)+' );

-- Is there a way to ensure that this table only ever has one row?
CREATE TABLE "Version" (
       version                  INTEGER         PRIMARY KEY
);

CREATE TABLE "User" (
       user_id                  SERIAL8         PRIMARY KEY,
       email_address            email_address   UNIQUE  NOT NULL,
       -- username is here primarily so we can uniquely identify
       -- system-created users even when the system's hostname
       -- changes, for normal users it can just be their email address
       username                 VARCHAR(255)    UNIQUE  NOT NULL,
       display_name             VARCHAR(255)    NOT NULL DEFAULT '',
       -- RFC2307 Blowfish crypt
       password                 VARCHAR(67)     NULL,
       openid_uri               VARCHAR(255)    UNIQUE  NULL,
       -- SHA1 in hex form
       activation_key           VARCHAR(40)     UNIQUE  NULL,
       is_admin                 BOOLEAN         NOT NULL DEFAULT FALSE,
       is_system_user           BOOLEAN         NOT NULL DEFAULT FALSE,
       is_disabled              BOOLEAN         NOT NULL DEFAULT FALSE,
       creation_datetime        TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       last_modified_datetime   TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       time_zone                VARCHAR(50)     NOT NULL DEFAULT 'UTC',
       locale_code              VARCHAR(20)     NOT NULL DEFAULT 'en_US',
       created_by_user_id       INT8            NULL,
       CONSTRAINT valid_user_record
           CHECK ( ( password != ''
                     OR ( openid_uri IS NOT NULL AND openid_uri != '' ) )
                     OR is_system_user )
);

CREATE TABLE "Account" (
       account_id               SERIAL8         PRIMARY KEY,
       name                     VARCHAR(255)    UNIQUE  NOT NULL,
       CONSTRAINT valid_name CHECK ( name != '' )
);

CREATE TABLE "AccountAdmin" (
       account_id               INT8            NOT NULL,
       user_id                  INT8            NOT NULL,
       PRIMARY KEY ( account_id, user_id )
);

CREATE INDEX "AccountAdmin_user_id" ON "AccountAdmin" (user_id);

CREATE DOMAIN uri_path_piece AS VARCHAR(255)
       CONSTRAINT valid_uri_path_piece CHECK ( VALUE ~ E'^[a-zA-Z0-9_\-]+$' );

CREATE TABLE "Wiki" (
       wiki_id                  SERIAL8         PRIMARY KEY,
       title                    VARCHAR(255)    UNIQUE  NOT NULL,
       -- This will be used in a URI path (/short-name/page/SomePage)
       -- or as a hostname prefix (short-name.wiki.example.com)
       short_name               uri_path_piece  UNIQUE  NOT NULL,
       domain_id                INT8            NOT NULL,
       account_id               INT8            NOT NULL,
       user_id                  INT8            NOT NULL,
       creation_datetime        TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       CONSTRAINT valid_title CHECK ( title != '' )
);

CREATE INDEX "Wiki_domain_id" ON "Wiki" (domain_id);
CREATE INDEX "Wiki_account_id" ON "Wiki" (account_id);
CREATE INDEX "Wiki_user_id" ON "Wiki" (user_id);

CREATE DOMAIN hostname AS VARCHAR(255)
       CONSTRAINT valid_hostname CHECK ( VALUE ~ E'^[^\\.]+(?:\\.[^\\.]+)+$' );

CREATE TABLE "Domain" (
       domain_id          SERIAL             PRIMARY KEY,
       web_hostname       VARCHAR(255)       UNIQUE  NOT NULL,
       email_hostname     VARCHAR(255)       NOT NULL,
       requires_ssl       BOOLEAN            DEFAULT FALSE,
       creation_datetime  TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       CONSTRAINT valid_web_hostname CHECK ( web_hostname != '' ),
       CONSTRAINT valid_email_hostname CHECK ( email_hostname != '' )
);

CREATE TABLE "Locale" (
       locale_code        VARCHAR(20)        PRIMARY KEY
);

CREATE TABLE "Country" (
       iso_code           CHAR(2)            PRIMARY KEY,
       name               VARCHAR(255)       UNIQUE  NOT NULL,
       locale_code        VARCHAR(20)        NOT NULL,
       CONSTRAINT valid_iso_code CHECK ( iso_code != '' ),
       CONSTRAINT valid_name CHECK ( name != '' )
);

CREATE TABLE "TimeZone" (
       olson_name         VARCHAR(255)       PRIMARY KEY,
       iso_code           CHAR(2)            NOT NULL,
       description        VARCHAR(100)       NOT NULL,
       display_order      INTEGER            NOT NULL,
       CONSTRAINT valid_olson_name CHECK ( olson_name != '' ),
       CONSTRAINT valid_iso_code CHECK ( iso_code != '' ),
       CONSTRAINT valid_description CHECK ( description != '' ),
       CONSTRAINT valid_display_order CHECK ( display_order > 0 )
-- unique constraints are not deferrable
--       CONSTRAINT TimeZone_id_display_order_ck
--                  UNIQUE ( iso_code, display_order )
--                  INITIALLY DEFERRED
);

CREATE TABLE "Role" (
       role_id                  SERIAL8         PRIMARY KEY,
       name                     VARCHAR(50)     UNIQUE  NOT NULL
);

CREATE TABLE "Permission" (
       permission_id            SERIAL8         PRIMARY KEY,
       name                     VARCHAR(50)     UNIQUE  NOT NULL
);

CREATE TABLE "UserWikiRole" (
       user_id                  INT8            NOT NULL,
       wiki_id                  INT8            NOT NULL,
       role_id                  INT8            NOT NULL,
       PRIMARY KEY ( user_id, wiki_id )
);

CREATE TABLE "WikiRolePermission" (
       wiki_id                  INT8            NOT NULL,
       role_id                  INT8            NOT NULL,
       permission_id            INT8            NOT NULL,
       PRIMARY KEY ( wiki_id, role_id, permission_id )
);

CREATE DOMAIN revision AS INT
       CONSTRAINT valid_revision CHECK ( VALUE > 0 );

CREATE TABLE "Page" (
       page_id                  SERIAL8         PRIMARY KEY,
       title                    VARCHAR(255)    NOT NULL,
       uri_path                 VARCHAR(255)    NOT NULL,
       is_archived              BOOLEAN         NOT NULL DEFAULT FALSE,
       wiki_id                  INT8            NOT NULL,
       user_id                  INT8            NOT NULL,
       -- This is only false for system-generated pages like FrontPage and
       -- Help
       can_be_renamed           BOOLEAN         NOT NULL DEFAULT TRUE,
       cached_content           BYTEA           NULL,
       UNIQUE ( wiki_id, title ),
       UNIQUE ( wiki_id, uri_path ),
       CONSTRAINT valid_title CHECK ( title != '' )
);

CREATE INDEX "Page_wiki_id" ON "Page" (wiki_id);
CREATE INDEX "Page_user_id" ON "Page" (user_id);

CREATE TABLE "PageSearchableText" (
       page_id                  INT8            PRIMARY KEY,
       ts_text                  tsvector        NULL
);

CREATE INDEX "PageSearchableText_ts_text" ON "PageSearchableText" USING GIN(ts_text);

CREATE TABLE "PageRevision" (
       page_id                  INT8            NOT NULL,
       revision_number          revision        NOT NULL,
       content                  TEXT            NOT NULL,
       user_id                  INT8            NOT NULL,
       creation_datetime        TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       comment                  TEXT            NULL,
       is_restoration_of_revision_number        INTEGER         NULL,
       PRIMARY KEY ( page_id, revision_number ),
       CONSTRAINT is_restoration_of_revision_number_is_lower_than_revision_number
           CHECK ( is_restoration_of_revision_number IS NULL
                   OR
                   is_restoration_of_revision_number < revision_number )
);

CREATE INDEX "PageRevision_user_id" ON "PageRevision" (user_id);

CREATE FUNCTION update_or_insert_page_searchable_text(id INT8, title VARCHAR(255), content TEXT) RETURNS VOID AS $$
DECLARE
    ts_text_val tsvector;
BEGIN
    ts_text_val :=
        setweight(to_tsvector('pg_catalog.english', title), 'A') ||
        setweight(to_tsvector('pg_catalog.english', content), 'B');

    LOOP
        UPDATE "PageSearchableText"
           SET ts_text = ts_text_val
         WHERE page_id = id;

        IF found THEN
            RETURN;
        END IF;

        BEGIN
            INSERT INTO  "PageSearchableText"
              ( page_id, ts_text )
            VALUES
              ( id, ts_text_val );
        EXCEPTION WHEN unique_violation THEN
        END;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION page_tsvector_trigger() RETURNS trigger AS $$
DECLARE
    new_content TEXT;
BEGIN        
    IF NEW.title = OLD.title THEN
        return NEW;
    END IF;

    SELECT content INTO new_content
      FROM "PageRevision"
     WHERE page_id = NEW.page_id
       AND revision_number =
           ( SELECT MAX(revision_number)
               FROM "PageRevision"
              WHERE page_id = NEW.page_id );

    IF new_content IS NULL THEN
        return NEW;
    END IF;

    PERFORM update_or_insert_page_searchable_text( NEW.page_id, NEW.title, new_content );    

    return NEW;
END;
$$ LANGUAGE plpgsql;

CREATE FUNCTION page_revision_tsvector_trigger() RETURNS trigger AS $$
DECLARE
    existing_title VARCHAR(255);
BEGIN
    SELECT title INTO existing_title
      FROM "Page"
     WHERE page_id = NEW.page_id;

    PERFORM update_or_insert_page_searchable_text( NEW.page_id, existing_title, NEW.content );    

    return NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ts_text_sync BEFORE UPDATE
       ON "Page" FOR EACH ROW EXECUTE PROCEDURE page_tsvector_trigger();

CREATE TRIGGER page_revision_ts_text_sync AFTER INSERT
       ON "PageRevision" FOR EACH ROW EXECUTE PROCEDURE page_revision_tsvector_trigger();

CREATE TABLE "PageTag" (
       page_id                  INT8            NOT NULL,
       tag_id                   INT8            NOT NULL,
       PRIMARY KEY ( page_id, tag_id )
);

CREATE INDEX "PageTag_tag_id" ON "PageTag" (tag_id);

CREATE TABLE "Tag" (
       tag_id                   SERIAL8         PRIMARY KEY,
       tag                      VARCHAR(200)    NOT NULL,
       wiki_id                  INT8            NOT NULL,
       CONSTRAINT valid_tag CHECK ( tag != '' ),
       UNIQUE ( tag, wiki_id )
);

CREATE INDEX "Tag_wiki_id" ON "Tag" (wiki_id);

CREATE TABLE "PageFileLink" (
       page_id                  INT8            NOT NULL,
       file_id                  INT8            NOT NULL,
       PRIMARY KEY ( page_id, file_id )
);

CREATE TABLE "Comment" (
       comment_id               SERIAL8         PRIMARY KEY,
       page_id                  INT8            NOT NULL,
       user_id                  INT8            NOT NULL,
       revision_number          revision        NOT NULL,
       title                    VARCHAR(255)    NOT NULL,
       body                     TEXT            NOT NULL,
       creation_datetime        TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       last_modified_datetime   TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       CONSTRAINT valid_body CHECK ( body != '' )
);

CREATE INDEX "Comment_page_id" ON "Comment" (page_id);
CREATE INDEX "Comment_user_id" ON "Comment" (user_id);

-- This is a cache, since the same information could be retrieved by
-- looking at the latest revision content for each page as
-- needed. Obviously, that would be prohibitively expensive.
CREATE TABLE "PageLink" (
       from_page_id             INT8            NOT NULL,
       to_page_id               INT8            NOT NULL,
       PRIMARY KEY ( from_page_id, to_page_id )
);

CREATE INDEX "PageLink_to_page_id" ON "PageLink" (to_page_id);

-- This stores links to pages which do not yet exist. When a page is created,
-- any pending links can be removed and put into the PageLink table
-- instead. This table can also be used to generate a list of wanted pages.
CREATE TABLE "PendingPageLink" (
       from_page_id             INT8            NOT NULL,
       to_wiki_id               INT8            NOT NULL,
       to_page_title            VARCHAR(255)    NOT NULL,
       PRIMARY KEY ( from_page_id, to_wiki_id, to_page_title )
);

CREATE INDEX "PendingPageLink_to_wiki_id_to_page_title" ON "PendingPageLink" (to_wiki_id, to_page_title);

CREATE TABLE "PageView" (
       page_id                  INT8            NOT NULL,
       user_id                  INT8            NOT NULL,
       view_datetime            TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       PRIMARY KEY ( page_id, user_id, view_datetime )
);

CREATE INDEX "PageView_user_id" ON "PageView" (user_id);

CREATE DOMAIN filename AS VARCHAR(255)
       CONSTRAINT no_slashes CHECK ( VALUE ~ E'^[^\\\\/]+$' );

CREATE TABLE "File" (
       file_id                  SERIAL8         PRIMARY KEY,
       filename                 filename       NOT NULL,
       mime_type                VARCHAR(255)    NOT NULL,
       file_size                INTEGER         NOT NULL,
       contents                 BYTEA           NOT NULL,
       creation_datetime        TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       user_id                  INT8            NOT NULL,
       wiki_id                  INT8            NOT NULL,
       UNIQUE (filename, wiki_id),
       CONSTRAINT valid_filename CHECK ( filename != '' ),
       CONSTRAINT valid_file_size CHECK ( file_size > 0 )
);

CREATE TABLE "SystemLog" (
       log_id             SERIAL8            PRIMARY KEY,
       user_id            INT8               NOT NULL,
       wiki_id            INT8               NULL,
       page_id            INT8               NULL,
       log_datetime       TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       message            VARCHAR(255)       NOT NULL,
       data_blob          BYTEA              NULL
);

CREATE TABLE "Session" (
       id                 CHAR(72)           PRIMARY KEY,
       session_data       BYTEA              NOT NULL,
       expires            INT                NOT NULL
);

ALTER TABLE "User" ADD CONSTRAINT "User_created_by_user_id"
  FOREIGN KEY ("created_by_user_id") REFERENCES "User" ("user_id")
  ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "User" ADD CONSTRAINT "User_locale_code"
  FOREIGN KEY ("locale_code") REFERENCES "Locale" ("locale_code")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "AccountAdmin" ADD CONSTRAINT "AccountAdmin_account_id"
  FOREIGN KEY ("account_id") REFERENCES "Account" ("account_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "AccountAdmin" ADD CONSTRAINT "AccountAdmin_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Wiki" ADD CONSTRAINT "Wiki_domain_id"
  FOREIGN KEY ("domain_id") REFERENCES "Domain" ("domain_id")
  ON DELETE SET DEFAULT ON UPDATE CASCADE;

ALTER TABLE "Wiki" ADD CONSTRAINT "Wiki_account_id"
  FOREIGN KEY ("account_id") REFERENCES "Account" ("account_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Wiki" ADD CONSTRAINT "Wiki_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "Country" ADD CONSTRAINT "Country_locale_code"
  FOREIGN KEY ("locale_code") REFERENCES "Locale" ("locale_code")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "TimeZone" ADD CONSTRAINT "TimeZone_iso_code"
  FOREIGN KEY ("iso_code") REFERENCES "Country" ("iso_code")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "UserWikiRole" ADD CONSTRAINT "UserWikiRole_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "UserWikiRole" ADD CONSTRAINT "UserWikiRole_wiki_id"
  FOREIGN KEY ("wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "UserWikiRole" ADD CONSTRAINT "UserWikiRole_role_id"
  FOREIGN KEY ("role_id") REFERENCES "Role" ("role_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "WikiRolePermission" ADD CONSTRAINT "WikiRolePermission_wiki_id"
  FOREIGN KEY ("wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "WikiRolePermission" ADD CONSTRAINT "WikiRolePermission_role_id"
  FOREIGN KEY ("role_id") REFERENCES "Role" ("role_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "WikiRolePermission" ADD CONSTRAINT "WikiRolePermission_permission_id"
  FOREIGN KEY ("permission_id") REFERENCES "Permission" ("permission_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Page" ADD CONSTRAINT "Page_wiki_id"
  FOREIGN KEY ("wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Page" ADD CONSTRAINT "Page_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageSearchableText" ADD CONSTRAINT "PageSearchableText_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageRevision" ADD CONSTRAINT "PageRevision_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageRevision" ADD CONSTRAINT "PageRevision_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageTag" ADD CONSTRAINT "PageTag_page_id_revision_number"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageTag" ADD CONSTRAINT "PageTag_tag_id"
  FOREIGN KEY ("tag_id") REFERENCES "Tag" ("tag_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Tag" ADD CONSTRAINT "Tag_wiki_id"
  FOREIGN KEY ("wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageFileLink" ADD CONSTRAINT "PageFileLink_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageFileLink" ADD CONSTRAINT "PageFileLink_file_id"
  FOREIGN KEY ("file_id") REFERENCES "File" ("file_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Comment" ADD CONSTRAINT "Page_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "Comment" ADD CONSTRAINT "Comment_page_id_revision_number"
  FOREIGN KEY ("page_id", "revision_number") REFERENCES "PageRevision" ("page_id", "revision_number")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageLink" ADD CONSTRAINT "PageLink_from_page_id"
  FOREIGN KEY ("from_page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageLink" ADD CONSTRAINT "PageLink_to_page_id"
  FOREIGN KEY ("to_page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PendingPageLink" ADD CONSTRAINT "PendingPageLink_from_page_id"
  FOREIGN KEY ("from_page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PendingPageLink" ADD CONSTRAINT "PendingPageLink_to_wiki_id"
  FOREIGN KEY ("to_wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageView" ADD CONSTRAINT "PageView_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "PageView" ADD CONSTRAINT "PageView_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "File" ADD CONSTRAINT "File_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "File" ADD CONSTRAINT "File_wiki_id"
  FOREIGN KEY ("wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "SystemLog" ADD CONSTRAINT "SystemLog_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "SystemLog" ADD CONSTRAINT "SystemLog_wiki_id"
  FOREIGN KEY ("wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE SET NULL ON UPDATE CASCADE;

ALTER TABLE "SystemLog" ADD CONSTRAINT "SystemLog_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE RESTRICT ON UPDATE CASCADE;

INSERT INTO "Version" (version) VALUES (1);
