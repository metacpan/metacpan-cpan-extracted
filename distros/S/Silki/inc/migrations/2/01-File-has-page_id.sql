SET CLIENT_MIN_MESSAGES = ERROR;

ALTER TABLE "File"
  ADD COLUMN page_id  INT8  NULL;

UPDATE "File"
   SET page_id =
       ( SELECT page_id
           FROM "PageFileLink"
          WHERE "PageFileLink".file_id = "File".file_id );

UPDATE "File"
   SET page_id =
       ( SELECT page_id
           FROM "Page"
          WHERE "Page".wiki_id = "File".wiki_id
            AND "Page".title = 'Front Page' )
 WHERE page_id IS NULL;

ALTER TABLE "File"
  ALTER COLUMN page_id  SET NOT NULL;

ALTER TABLE "File"
  DROP COLUMN wiki_id;

ALTER TABLE "File" ADD CONSTRAINT "File_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "File"
  ADD CONSTRAINT "File_filename_key"
  UNIQUE ( filename, page_id );

ALTER TABLE "File"
  DROP CONSTRAINT "File_user_id";

ALTER TABLE "File" ADD CONSTRAINT "File_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;

DROP TABLE "PageFileLink";

ALTER TABLE "SystemLog"
  DROP CONSTRAINT "SystemLog_page_id";

ALTER TABLE "SystemLog" ADD CONSTRAINT "SystemLog_page_id"
  FOREIGN KEY ("page_id") REFERENCES "Page" ("page_id")
  ON DELETE SET NULL ON UPDATE CASCADE;
