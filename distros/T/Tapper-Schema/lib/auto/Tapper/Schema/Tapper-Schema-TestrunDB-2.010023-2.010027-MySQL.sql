-- Convert schema 'upgrades/Tapper-Schema-TestrunDB-2.010023-MySQL.sql' to 'Tapper::Schema::TestrunDB v2.010027':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `scenario` (
  id integer(11) NOT NULL auto_increment,
  type VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE `scenario_element` (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  scenario_id integer(11) NOT NULL,
  is_fitted integer(1) NOT NULL DEFAULT '0',
  INDEX scenario_element_idx_scenario_id (scenario_id),
  INDEX scenario_element_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  CONSTRAINT scenario_element_fk_scenario_id FOREIGN KEY (scenario_id) REFERENCES `scenario` (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT scenario_element_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES `testrun` (id) ON DELETE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE testrun DROP COLUMN test_program,
                    ADD COLUMN rerun_on_error integer(11) DEFAULT '0';

ALTER TABLE testrun_scheduling CHANGE COLUMN status status VARCHAR(255) DEFAULT 'prepare';


COMMIT;

