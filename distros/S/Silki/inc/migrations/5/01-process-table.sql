SET CLIENT_MIN_MESSAGES = ERROR;

CREATE TABLE "Process" (
       process_id         SERIAL8            PRIMARY KEY,
       system_pid         INT4               NULL,
       wiki_id            INT8               NULL,
       status             TEXT               NOT NULL DEFAULT '',
       is_complete        BOOL               DEFAULT FALSE,
       was_successful     BOOL               DEFAULT FALSE,
       final_result       TEXT               DEFAULT '',
       creation_datetime       TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP,
       last_modified_datetime  TIMESTAMP WITHOUT TIME ZONE  NOT NULL DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE "Process" ADD CONSTRAINT "Process_wiki_id"
  FOREIGN KEY ("wiki_id") REFERENCES "Wiki" ("wiki_id")
  ON DELETE SET NULL ON UPDATE CASCADE;
