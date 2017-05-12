-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010032-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010033':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `tap` (
  `id` integer(11) NOT NULL auto_increment,
  `report_id` integer(11) NOT NULL,
  `tap` LONGBLOB NOT NULL DEFAULT '',
  `tapdom` LONGBLOB DEFAULT '',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  INDEX `tap_idx_report_id` (`report_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `tap_fk_report_id` FOREIGN KEY (`report_id`) REFERENCES `report` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

INSERT INTO tap(report_id, tap, tapdom) SELECT id, tap, tapdom FROM report where not isnull(tap) or not isnull(tapdom);


ALTER TABLE report DROP INDEX report_idx_id,
                   DROP COLUMN tap,
                   DROP COLUMN tapdom;

DROP TABLE IF EXISTS reportgroup;


COMMIT;

