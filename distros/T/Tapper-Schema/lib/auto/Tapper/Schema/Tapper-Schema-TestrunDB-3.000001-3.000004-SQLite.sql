-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000001-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-TestrunDB-3.000004-SQLite.sql':;

BEGIN;

ALTER TABLE host ADD COLUMN is_deleted TINYINT DEFAULT 0;

CREATE TEMPORARY TABLE message_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11),
  message VARCHAR(65000),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME,
  FOREIGN KEY(testrun_id) REFERENCES testrun(id)
);

INSERT INTO message_temp_alter SELECT id, testrun_id, message, type, created_at, updated_at FROM message;

DROP TABLE message;

CREATE TABLE message (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11),
  message VARCHAR(65000),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME,
  FOREIGN KEY(testrun_id) REFERENCES testrun(id)
);

CREATE INDEX message_idx_testrun_id03 ON message (testrun_id);

INSERT INTO message SELECT id, testrun_id, message, type, created_at, updated_at FROM message_temp_alter;

DROP TABLE message_temp_alter;

ALTER TABLE queue ADD COLUMN is_deleted TINYINT DEFAULT 0;

CREATE TEMPORARY TABLE queue_host_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY(host_id) REFERENCES host(id),
  FOREIGN KEY(queue_id) REFERENCES queue(id)
);

INSERT INTO queue_host_temp_alter SELECT id, queue_id, host_id FROM queue_host;

DROP TABLE queue_host;

CREATE TABLE queue_host (
  id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY(host_id) REFERENCES host(id),
  FOREIGN KEY(queue_id) REFERENCES queue(id)
);

CREATE INDEX queue_host_idx_host_id03 ON queue_host (host_id);

CREATE INDEX queue_host_idx_queue_id03 ON queue_host (queue_id);

INSERT INTO queue_host SELECT id, queue_id, host_id FROM queue_host_temp_alter;

DROP TABLE queue_host_temp_alter;

CREATE TEMPORARY TABLE testrun_requested_host_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY(host_id) REFERENCES host(id),
  FOREIGN KEY(testrun_id) REFERENCES testrun(id)
);

INSERT INTO testrun_requested_host_temp_alter SELECT id, testrun_id, host_id FROM testrun_requested_host;

DROP TABLE testrun_requested_host;

CREATE TABLE testrun_requested_host (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY(host_id) REFERENCES host(id),
  FOREIGN KEY(testrun_id) REFERENCES testrun(id)
);

CREATE INDEX testrun_requested_host_idx_00 ON testrun_requested_host (host_id);

CREATE INDEX testrun_requested_host_idx_00 ON testrun_requested_host (testrun_id);

INSERT INTO testrun_requested_host SELECT id, testrun_id, host_id FROM testrun_requested_host_temp_alter;

DROP TABLE testrun_requested_host_temp_alter;

CREATE TEMPORARY TABLE user_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255),
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);

INSERT INTO user_temp_alter SELECT id, name, login, password FROM user;

DROP TABLE user;

CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255),
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);

INSERT INTO user SELECT id, name, login, password FROM user_temp_alter;

DROP TABLE user_temp_alter;


COMMIT;

