SET CLIENT_MIN_MESSAGES = ERROR;

CREATE TABLE "UserImage" (
       user_id                  INT8            PRIMARY KEY,
       mime_type                citext          NOT NULL,
       file_size                INTEGER         NOT NULL,
       contents                 BYTEA           NOT NULL,
       creation_datetime        TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       CONSTRAINT valid_mime_type
           CHECK ( mime_type = 'image/gif' OR mime_type = 'image/png' OR mime_type = 'image/jpeg' )
);       

ALTER TABLE "UserImage" ADD CONSTRAINT "UserImage_user_id"
  FOREIGN KEY ("user_id") REFERENCES "User" ("user_id")
  ON DELETE CASCADE ON UPDATE CASCADE;
