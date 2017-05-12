-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010034-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010035':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `testplan_instance` (
  id integer(11) NOT NULL auto_increment,
  path VARCHAR(255) DEFAULT '',
  evaluated_testplan text DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE message CHANGE COLUMN message message text;

ALTER TABLE state CHANGE COLUMN state state text;

ALTER TABLE testrun ADD COLUMN testplan_id integer(11),
                    ADD INDEX testrun_idx_testplan_id (testplan_id),
                    ADD CONSTRAINT testrun_fk_testplan_id FOREIGN KEY (testplan_id) REFERENCES testplan_instance (id) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

