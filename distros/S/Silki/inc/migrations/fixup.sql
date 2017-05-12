-- These are manual fixes for the bad migrations in previous releases of Silki

-- 1 to 2

ALTER TABLE "File"
  ADD CONSTRAINT "File_filename_key"
  UNIQUE ( filename, page_id );

ALTER TABLE "File"
  DROP CONSTRAINT "File_user_id";

ALTER TABLE "File" ADD CONSTRAINT "File_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "SystemLog"
  DROP CONSTRAINT "SystemLog_page_id";

ALTER TABLE "SystemLog" ADD CONSTRAINT "SystemLog_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE SET NULL ON UPDATE CASCADE;

-- 2 to 3

ALTER TABLE "Account"
      DROP CONSTRAINT valid_name;

ALTER TABLE "Account"
      ADD CONSTRAINT valid_name CHECK (name <> '');

ALTER TABLE "Wiki"
      DROP CONSTRAINT valid_title;

ALTER TABLE "Wiki"
      ADD CONSTRAINT valid_title CHECK ( title != '' );

ALTER TABLE "Domain"
      DROP CONSTRAINT valid_web_hostname;

ALTER TABLE "Domain"
      ADD CONSTRAINT valid_web_hostname CHECK ( web_hostname != '' );

ALTER TABLE "Domain"
      DROP CONSTRAINT valid_email_hostname;

ALTER TABLE "Domain"
      ADD CONSTRAINT valid_email_hostname CHECK ( email_hostname != '' );

ALTER TABLE "Country"
      DROP CONSTRAINT valid_name;

ALTER TABLE "Country"
      ADD CONSTRAINT valid_name CHECK ( name != '' );

ALTER TABLE "Page"
      DROP CONSTRAINT valid_title;

ALTER TABLE "Page"
      ADD CONSTRAINT valid_title CHECK ( title != '' );

ALTER TABLE "Page"
      ALTER COLUMN uri_path TYPE citext;

ALTER TABLE "Comment"
      ALTER COLUMN title TYPE TEXT;

ALTER TABLE "Tag"
      DROP CONSTRAINT valid_tag;

ALTER TABLE "Tag"
      ADD CONSTRAINT valid_tag CHECK ( tag != '' );
