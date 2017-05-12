-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000006-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000007-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE notification_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id INT(11),
  persist INT(1),
  event VARCHAR(255) NOT NULL,
  filter TEXT NOT NULL,
  comment VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME,
  FOREIGN KEY(user_id) REFERENCES user(id)
);

INSERT INTO notification_temp_alter SELECT id, user_id, persist, event, filter, comment, created_at, updated_at FROM notification;

DROP TABLE notification;

CREATE TABLE notification (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id INT(11),
  persist INT(1),
  event VARCHAR(255) NOT NULL,
  filter TEXT NOT NULL,
  comment VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME,
  FOREIGN KEY(user_id) REFERENCES user(id)
);

CREATE INDEX notification_idx_user_id03 ON notification (user_id);

INSERT INTO notification SELECT id, user_id, persist, event, filter, comment, created_at, updated_at FROM notification_temp_alter;

DROP TABLE notification_temp_alter;

CREATE UNIQUE INDEX unique_login02 ON user (login);


COMMIT;

