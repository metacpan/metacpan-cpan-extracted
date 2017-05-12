-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010032-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010037':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `tap` (
  id integer(11) NOT NULL auto_increment,
  report_id integer(11) NOT NULL,
  tap LONGBLOB NOT NULL DEFAULT '',
  tap_is_archive integer(11),
  tapdom LONGBLOB DEFAULT '',
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  INDEX tap_idx_report_id (report_id),
  PRIMARY KEY (id),
  CONSTRAINT tap_fk_report_id FOREIGN KEY (report_id) REFERENCES `report` (id) ON DELETE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

ALTER TABLE report DROP FOREIGN KEY report_fk_id,
                   DROP FOREIGN KEY report_fk_id_1,
                   DROP INDEX report_idx_id,
                   DROP COLUMN tap,
                   DROP COLUMN tapdom,
                   DROP COLUMN hardwaredb_systems_id;

ALTER TABLE reportgrouparbitrary ADD INDEX reportgrouparbitrary_idx_report_id (report_id),
                                 ADD CONSTRAINT reportgrouparbitrary_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE;

ALTER TABLE reportgrouptestrun ADD INDEX reportgrouptestrun_idx_report_id (report_id),
                               ADD CONSTRAINT reportgrouptestrun_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE;

ALTER TABLE reportsection ADD COLUMN ticket_url VARCHAR(255),
                          ADD COLUMN wiki_url VARCHAR(255),
                          ADD COLUMN planning_id VARCHAR(255),
                          ADD COLUMN tags VARCHAR(255);

DROP TABLE reportgroup;


COMMIT;

