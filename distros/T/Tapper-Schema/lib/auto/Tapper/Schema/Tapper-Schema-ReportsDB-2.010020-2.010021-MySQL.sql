-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010020-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010021':;

BEGIN;

ALTER TABLE report DROP FOREIGN KEY report_fk_id,
                   DROP FOREIGN KEY report_fk_id_1,
                   DROP INDEX report_idx_id,
                   CHANGE COLUMN tapdata tapdom LONGBLOB DEFAULT '';

ALTER TABLE reportgroup ADD INDEX reportgroup_idx_report_id (report_id),
                        ADD CONSTRAINT reportgroup_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id),
                        ENGINE=InnoDB;

ALTER TABLE reportgrouparbitrary ADD INDEX reportgrouparbitrary_idx_report_id (report_id),
                                 ADD CONSTRAINT reportgrouparbitrary_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id);

ALTER TABLE reportgrouptestrun ADD INDEX reportgrouptestrun_idx_report_id (report_id),
                               ADD CONSTRAINT reportgrouptestrun_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id);

ALTER TABLE reportsection CHANGE COLUMN language_description language_description text,
                          ADD INDEX reportsection_idx_report_id (report_id),
                          ADD CONSTRAINT reportsection_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE ON UPDATE CASCADE,
                          ENGINE=InnoDB;


COMMIT;

