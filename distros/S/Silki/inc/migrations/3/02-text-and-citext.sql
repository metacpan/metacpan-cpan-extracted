SET CLIENT_MIN_MESSAGES = ERROR;

ALTER TABLE "User"
      ALTER COLUMN email_address TYPE VARCHAR(255);

DROP DOMAIN email_address;

CREATE DOMAIN email_address AS citext
       CONSTRAINT valid_email_address CHECK ( VALUE ~ E'^.+@.+(?:\\..+)+' );

ALTER TABLE "User"
      ALTER COLUMN email_address TYPE email_address;

ALTER TABLE "User"
      ALTER COLUMN username TYPE TEXT;

ALTER TABLE "User"
      ALTER COLUMN display_name TYPE citext;

ALTER TABLE "User"
      ALTER COLUMN display_name SET DEFAULT '';

ALTER TABLE "User"
      ALTER COLUMN openid_uri TYPE TEXT;

ALTER TABLE "User"
      ALTER COLUMN time_zone TYPE TEXT;

ALTER TABLE "User"
      ALTER COLUMN time_zone SET DEFAULT 'UTC';

ALTER TABLE "User"
      ALTER COLUMN locale_code TYPE TEXT;

ALTER TABLE "User"
      ALTER COLUMN locale_code SET DEFAULT 'en_US';

ALTER TABLE "Account"
      ALTER COLUMN name TYPE citext;

ALTER TABLE "Account"
      DROP CONSTRAINT valid_name;

ALTER TABLE "Account"
      ADD CONSTRAINT valid_name CHECK ( name != '' );

ALTER TABLE "Wiki"
      ALTER COLUMN title TYPE citext;

ALTER TABLE "Wiki"
      DROP CONSTRAINT valid_title;

ALTER TABLE "Wiki"
      ADD CONSTRAINT valid_title CHECK ( title != '' );

DROP DOMAIN hostname;

CREATE DOMAIN hostname AS citext
       CONSTRAINT valid_hostname CHECK ( VALUE ~ E'^[^\\.]+(?:\\.[^\\.]+)+$' );

ALTER TABLE "Domain"
      ALTER COLUMN web_hostname TYPE hostname;

ALTER TABLE "Domain"
      ALTER COLUMN email_hostname TYPE hostname;

ALTER TABLE "Domain"
      DROP CONSTRAINT valid_web_hostname;

ALTER TABLE "Domain"
      ADD CONSTRAINT valid_web_hostname CHECK ( web_hostname != '' );

ALTER TABLE "Domain"
      DROP CONSTRAINT valid_email_hostname;

ALTER TABLE "Domain"
      ADD CONSTRAINT valid_email_hostname CHECK ( email_hostname != '' );

ALTER TABLE "Locale"
      ALTER COLUMN locale_code TYPE TEXT;

ALTER TABLE "Country"
      ALTER COLUMN name TYPE citext;

ALTER TABLE "Country"
      ALTER COLUMN locale_code TYPE TEXT;

ALTER TABLE "Country"
      DROP CONSTRAINT valid_name;

ALTER TABLE "Country"
      ADD CONSTRAINT valid_name CHECK ( name != '' );

ALTER TABLE "TimeZone"
      ALTER COLUMN olson_name TYPE TEXT;

ALTER TABLE "TimeZone"
      ALTER COLUMN description TYPE TEXT;

ALTER TABLE "Role"
      ALTER COLUMN name TYPE citext;

ALTER TABLE "Permission"
      ALTER COLUMN name TYPE citext;

ALTER TABLE "Page"
      ALTER COLUMN title TYPE citext;

ALTER TABLE "Page"
      ALTER COLUMN uri_path TYPE citext;

ALTER TABLE "Page"
      DROP CONSTRAINT valid_title;

ALTER TABLE "Page"
      ADD CONSTRAINT valid_title CHECK ( title != '' );

DROP FUNCTION update_or_insert_page_searchable_text(id INT8, title VARCHAR(255), content TEXT);

CREATE OR REPLACE FUNCTION update_or_insert_page_searchable_text(id INT8, title citext, content TEXT) RETURNS VOID AS $$
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

CREATE OR REPLACE FUNCTION page_revision_tsvector_trigger() RETURNS trigger AS $$
DECLARE
    existing_title citext;
BEGIN
    SELECT title INTO existing_title
      FROM "Page"
     WHERE page_id = NEW.page_id;

    PERFORM update_or_insert_page_searchable_text( NEW.page_id, existing_title, NEW.content );    

    return NULL;
END;
$$ LANGUAGE plpgsql;

ALTER TABLE "Comment"
      ALTER COLUMN title TYPE text;

ALTER TABLE "Tag"
      ALTER COLUMN tag TYPE citext;

ALTER TABLE "Tag"
      DROP CONSTRAINT valid_tag;

ALTER TABLE "Tag"
      ADD CONSTRAINT valid_tag CHECK ( tag != '' );

ALTER TABLE "PendingPageLink"
      ALTER COLUMN to_page_title TYPE citext;

ALTER TABLE "File"
      ALTER COLUMN filename TYPE VARCHAR(255);

DROP DOMAIN filename;

CREATE DOMAIN filename AS citext
       CONSTRAINT no_slashes CHECK ( VALUE ~ E'^[^\\\\/]+$' );

ALTER TABLE "File"
      ALTER COLUMN filename TYPE filename;

ALTER TABLE "File"
      ALTER COLUMN mime_type TYPE citext;

ALTER TABLE "File"
      DROP CONSTRAINT valid_filename;

ALTER TABLE "File"
      ADD CONSTRAINT valid_filename CHECK ( filename != '' );

ALTER TABLE "SystemLog"
      ALTER COLUMN message TYPE TEXT;
