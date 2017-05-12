-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010016-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010018':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `host` (
  id integer(11) NOT NULL auto_increment,
  name VARCHAR(255) DEFAULT '',
  free TINYINT DEFAULT '0',
  active TINYINT DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE `testrun_requested_host` (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  host_id integer,
  INDEX testrun_requested_host_idx_host_id (host_id),
  INDEX testrun_requested_host_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  CONSTRAINT testrun_requested_host_fk_host_id FOREIGN KEY (host_id) REFERENCES `host` (id),
  CONSTRAINT testrun_requested_host_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES `testrun` (id)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE queue DROP COLUMN producer,
                  ADD UNIQUE unique_queue_name (name);

ALTER TABLE testrun_scheduling 
                               DROP COLUMN built,
                               DROP COLUMN active,
                               ADD COLUMN mergedqueue_seq integer(11),
                               ADD COLUMN host_id integer(11) DEFAULT '0',
                               ADD COLUMN status VARCHAR(255) DEFAULT 'prepare',
                               ADD COLUMN auto_rerun TINYINT DEFAULT '0',
                               CHANGE COLUMN id id integer(11) NOT NULL auto_increment,
                               CHANGE COLUMN testrun_id testrun_id integer(11) NOT NULL,
                               ADD INDEX testrun_scheduling_idx_host_id (host_id),
                               DROP PRIMARY KEY,
                               ADD PRIMARY KEY (id),
                               ADD CONSTRAINT testrun_scheduling_fk_host_id FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE;


COMMIT;

