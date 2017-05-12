-- Convert schema '/var/tmp/Tapper-Schema-ReportsDB-2.010015-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010016':

BEGIN;

SET foreign_key_checks=0;


CREATE TABLE `reportgrouparbitrary` (
  arbitrary_id VARCHAR(11) NOT NULL,
  report_id integer(11) NOT NULL,
  INDEX reportgrouparbitrary_idx_report_id (report_id),
  PRIMARY KEY (arbitrary_id, report_id),
  CONSTRAINT reportgrouparbitrary_fk_report_id FOREIGN KEY (report_id) REFERENCES `report` (id)
) ENGINE=InnoDB;


CREATE TABLE `reportgrouptestrun` (
  testrun_id integer(11) NOT NULL,
  report_id integer(11) NOT NULL,
  INDEX reportgrouptestrun_idx_report_id (report_id),
  PRIMARY KEY (testrun_id, report_id),
  CONSTRAINT reportgrouptestrun_fk_report_id FOREIGN KEY (report_id) REFERENCES `report` (id)
) ENGINE=InnoDB;


SET foreign_key_checks=1;


ALTER TABLE reportsection CHANGE COLUMN language_description language_description text;

COMMIT;
