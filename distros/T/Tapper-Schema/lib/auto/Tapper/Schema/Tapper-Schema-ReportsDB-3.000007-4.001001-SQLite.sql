-- Convert schema '/home/hmai/Projekte/Tapper/src/Tapper-Schema/lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000007-SQLite.sql' to '/home/hmai/Projekte/Tapper/src/Tapper-Schema/lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-4.001001-SQLite.sql':;

BEGIN;

CREATE TABLE owner (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);

CREATE UNIQUE INDEX unique_login ON owner (login);

CREATE TEMPORARY TABLE contact_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  owner_id INT(11) NOT NULL,
  address VARCHAR(255) NOT NULL,
  protocol VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO contact_temp_alter( id, address, protocol, created_at, updated_at) SELECT id, address, protocol, created_at, updated_at FROM contact;

DROP TABLE contact;

CREATE TABLE contact (
  id INTEGER PRIMARY KEY NOT NULL,
  owner_id INT(11) NOT NULL,
  address VARCHAR(255) NOT NULL,
  protocol VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX contact_idx_owner_id03 ON contact (owner_id);

INSERT INTO contact SELECT id, owner_id, address, protocol, created_at, updated_at FROM contact_temp_alter;

DROP TABLE contact_temp_alter;

CREATE TEMPORARY TABLE notification_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  owner_id INT(11),
  persist INT(1),
  event VARCHAR(255) NOT NULL,
  filter TEXT NOT NULL,
  comment VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO notification_temp_alter( id, persist, event, filter, comment, created_at, updated_at) SELECT id, persist, event, filter, comment, created_at, updated_at FROM notification;

DROP TABLE notification;

CREATE TABLE notification (
  id INTEGER PRIMARY KEY NOT NULL,
  owner_id INT(11),
  persist INT(1),
  event VARCHAR(255) NOT NULL,
  filter TEXT NOT NULL,
  comment VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX notification_idx_owner_id03 ON notification (owner_id);

INSERT INTO notification SELECT id, owner_id, persist, event, filter, comment, created_at, updated_at FROM notification_temp_alter;

DROP TABLE notification_temp_alter;

DROP INDEX ;

CREATE TEMPORARY TABLE reportcomment_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  owner_id INT(11),
  succession INT(10),
  comment TEXT NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES owner(id),
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO reportcomment_temp_alter( id, report_id, succession, comment, created_at, updated_at) SELECT id, report_id, succession, comment, created_at, updated_at FROM reportcomment;

DROP TABLE reportcomment;

CREATE TABLE reportcomment (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  owner_id INT(11),
  succession INT(10),
  comment TEXT NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES owner(id),
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX reportcomment_idx_owner_id03 ON reportcomment (owner_id);

CREATE INDEX reportcomment_idx_report_id03 ON reportcomment (report_id);

INSERT INTO reportcomment SELECT id, report_id, owner_id, succession, comment, created_at, updated_at FROM reportcomment_temp_alter;

DROP TABLE reportcomment_temp_alter;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP INDEX ;

DROP TABLE user;


COMMIT;

