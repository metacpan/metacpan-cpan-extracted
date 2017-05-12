-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010029-SQLite.sql' to 'upgrades/Tapper-Schema-TestrunDB-2.010030-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE topic_temp_alter (
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);

INSERT INTO topic_temp_alter SELECT name, description FROM topic;

DROP TABLE topic;

CREATE TABLE topic (
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);

INSERT INTO topic SELECT name, description FROM topic_temp_alter;

DROP TABLE topic_temp_alter;


COMMIT;

