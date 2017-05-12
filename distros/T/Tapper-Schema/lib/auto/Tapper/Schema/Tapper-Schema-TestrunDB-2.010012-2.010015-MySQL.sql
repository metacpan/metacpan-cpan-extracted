-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010012-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010015':

BEGIN;

SET foreign_key_checks=0;


CREATE TABLE queue (
  id integer(11) NOT NULL auto_increment,
  name VARCHAR(255) DEFAULT '',
  producer VARCHAR(255) DEFAULT '',
  priority integer(10) NOT NULL DEFAULT '0',
  runcount integer(10) NOT NULL DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  PRIMARY KEY (id)
) ENGINE=InnoDB;


CREATE TABLE testrun_requested_feature (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  feature VARCHAR(255) DEFAULT '',
  INDEX testrun_requested_feature_idx_testrun_id (testrun_id),
  PRIMARY KEY (testrun_id),
  CONSTRAINT testrun_requested_feature_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id)
) ENGINE=InnoDB;


CREATE TABLE testrun_scheduling (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  queue_id integer(11) DEFAULT '0',
  built integer(1) DEFAULT '0',
  active integer(1) DEFAULT '0',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  INDEX testrun_scheduling_idx_queue_id (queue_id),
  INDEX testrun_scheduling_idx_testrun_id (testrun_id),
  PRIMARY KEY (testrun_id),
  CONSTRAINT testrun_scheduling_fk_queue_id FOREIGN KEY (queue_id) REFERENCES queue (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT testrun_scheduling_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id) ON DELETE CASCADE
) ENGINE=InnoDB;


SET foreign_key_checks=1;


-- ALTER TABLE testrun CHANGE COLUMN created_at created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE testrun_precondition DROP FOREIGN KEY testrun_precondition_fk_precondition_id;
ALTER TABLE testrun_precondition ADD CONSTRAINT testrun_precondition_fk_precondition_id FOREIGN KEY (precondition_id) REFERENCES precondition (id) ON DELETE CASCADE ON UPDATE CASCADE;

COMMIT;
