-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010018-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010020':

BEGIN;

ALTER TABLE report ADD COLUMN tapdata LONGBLOB NOT NULL DEFAULT '',
                   CHANGE COLUMN tap tap LONGBLOB NOT NULL DEFAULT '',
                   ADD INDEX report_idx_id (id),
                   ADD CONSTRAINT report_fk_id FOREIGN KEY (id) REFERENCES reportgrouparbitrary (report_id) ON DELETE CASCADE ON UPDATE CASCADE,
                   ADD CONSTRAINT report_fk_id_1 FOREIGN KEY (id) REFERENCES reportgrouptestrun (report_id) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE reportgroup DROP FOREIGN KEY reportgroup_fk_report_id,
                        DROP INDEX reportgroup_idx_report_id,
                        ALTER TABLE reportgroup;
ALTER TABLE reportgrouparbitrary DROP FOREIGN KEY reportgrouparbitrary_fk_report_id,
                                 DROP INDEX reportgrouparbitrary_idx_report_id,
                                 CHANGE COLUMN arbitrary_id arbitrary_id VARCHAR(255) NOT NULL;
ALTER TABLE reportgrouptestrun DROP FOREIGN KEY reportgrouptestrun_fk_report_id,
                               DROP INDEX reportgrouptestrun_idx_report_id;
ALTER TABLE reportsection DROP FOREIGN KEY reportsection_fk_report_id,
                          DROP INDEX reportsection_idx_report_id,
                          CHANGE COLUMN language_description language_description text,
                          ALTER TABLE reportsection;

COMMIT;
