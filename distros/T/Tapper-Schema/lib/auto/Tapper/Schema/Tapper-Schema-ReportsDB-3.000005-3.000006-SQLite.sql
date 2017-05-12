-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000005-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000006-SQLite.sql':;

BEGIN;

CREATE TABLE contact (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id INT(11) NOT NULL,
  address VARCHAR(255) NOT NULL,
  protocol VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME,
  FOREIGN KEY(user_id) REFERENCES user(id)
);

CREATE INDEX contact_idx_user_id ON contact (user_id);

CREATE TABLE notification (
  id INTEGER PRIMARY KEY NOT NULL,
  user_id INT(11),
  persist INT(1),
  event VARCHAR(255) NOT NULL,
  condition TEXT NOT NULL,
  comment VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME,
  FOREIGN KEY(user_id) REFERENCES user(id)
);

CREATE INDEX notification_idx_user_id ON notification (user_id);

CREATE TABLE notification_event (
  id INTEGER PRIMARY KEY NOT NULL,
  message VARCHAR(255),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT 'CURRENT_TIMESTAMP',
  updated_at DATETIME
);


COMMIT;

