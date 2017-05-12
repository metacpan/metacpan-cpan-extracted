-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010032-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010036':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `host_feature` (
  id integer(11) NOT NULL auto_increment,
  host_id integer NOT NULL,
  entry VARCHAR(255) NOT NULL,
  value VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  INDEX host_feature_idx_host_id (host_id),
  PRIMARY KEY (id),
  CONSTRAINT host_feature_fk_host_id FOREIGN KEY (host_id) REFERENCES `host` (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `message` (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  message text,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  INDEX message_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  CONSTRAINT message_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES `testrun` (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `state` (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  state text,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  INDEX state_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  UNIQUE unique_testrun_id (testrun_id),
  CONSTRAINT state_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES `testrun` (id)
) ENGINE=InnoDB;

CREATE TABLE `testplan_instance` (
  id integer(11) NOT NULL auto_increment,
  path VARCHAR(255) DEFAULT '',
  name VARCHAR(255) DEFAULT '',
  evaluated_testplan text DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE testrun DROP COLUMN hardwaredb_systems_id,
                    ADD COLUMN testplan_id integer(11),
                    ADD INDEX testrun_idx_testplan_id (testplan_id),
                    ADD CONSTRAINT testrun_fk_testplan_id FOREIGN KEY (testplan_id) REFERENCES testplan_instance (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

