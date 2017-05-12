-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010015-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010016':;

BEGIN;

SET foreign_key_checks=0;

--CREATE TABLE `host` (
--  id integer(11) NOT NULL auto_increment,
--  name VARCHAR(255) DEFAULT '',
--  allowed_context VARCHAR(255) DEFAULT '',
--  busy VARCHAR(255) DEFAULT '',
--  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
--  updated_at datetime,
--  PRIMARY KEY (id)
--);

SET foreign_key_checks=1;

ALTER TABLE queue CHANGE COLUMN created_at created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE testrun CHANGE COLUMN created_at created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE testrun_requested_feature DROP INDEX ,
                                      CHANGE COLUMN id id integer(11) NOT NULL auto_increment,
                                      CHANGE COLUMN testrun_id testrun_id integer(11) NOT NULL,
                                      ADD PRIMARY KEY (id);

ALTER TABLE testrun_scheduling CHANGE COLUMN created_at created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;


COMMIT;

