create TABLE dev.logs (
  "log_timestamp" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  "log_duration" DOUBLE NOT NULL,
  "log_remote_ip" IP,
  "log_user_id" BIGINT,
  "log_admin_user_id" BIGINT, 
  "log_global" OBJECT,
  "log_session" OBJECT,
  "log_application" TEXT INDEX USING FULLTEXT,
  "log_application_version" DOUBLE,
  "log_api_endpoint" TEXT INDEX USING FULLTEXT,
  "log_api_version" DOUBLE,
  "log_method" TEXT INDEX USING FULLTEXT,
  "log_request" OBJECT,
  "log_type" TEXT,
  "log_error" OBJECT(STRICT) AS (
      "message" TEXT INDEX USING FULLTEXT,
      "data" OBJECT
  ),
  "log_url" TEXT INDEX USING FULLTEXT,
  "log_server" VARCHAR(50),
  "log_user_agent" VARCHAR,
  "log_affected_data" OBJECT(STRICT) AS (
     "object" TEXT,
     "id" BIGINT,
     "data" OBJECT
   ),
  "log_note" TEXT INDEX USING FULLTEXT
);

CREATE USER hmgadmin WITH (PASSWORD = 'sample');

GRANT ALL PRIVILEGES ON TABLE dev.logs TO hmgadmin;