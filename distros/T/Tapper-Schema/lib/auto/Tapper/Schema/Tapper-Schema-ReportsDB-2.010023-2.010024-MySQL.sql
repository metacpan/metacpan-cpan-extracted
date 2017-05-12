-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010023-MySQL.sql' to 'Tapper::Schema::ReportsDB v2.010024':;

BEGIN;

ALTER TABLE report ADD COLUMN hardwaredb_systems_id integer(11);

--ALTER TABLE reportgroup DROP FOREIGN KEY reportgroup_fk_report_id,
--                        DROP INDEX reportgroup_idx_report_id;
--
--ALTER TABLE reportgrouparbitrary DROP FOREIGN KEY reportgrouparbitrary_fk_report_id,
--                                 DROP INDEX reportgrouparbitrary_idx_report_id;
--
--ALTER TABLE reportgrouptestrun DROP FOREIGN KEY reportgrouptestrun_fk_report_id,
--                               DROP INDEX reportgrouptestrun_idx_report_id;
--
--ALTER TABLE reportsection DROP FOREIGN KEY reportsection_fk_report_id,
--                          DROP INDEX reportsection_idx_report_id,
--                          CHANGE COLUMN language_description language_description text;


COMMIT;

