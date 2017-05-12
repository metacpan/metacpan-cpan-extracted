-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010023-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010029-SQLite.sql':;

BEGIN;

CREATE TABLE reportgrouptestrunstats (
  testrun_id INTEGER PRIMARY KEY NOT NULL,
  total INT(10),
  failed INT(10),
  passed INT(10),
  parse_errors INT(10),
  skipped INT(10),
  todo INT(10),
  todo_passed INT(10),
  wait INT(10),
  success_ratio VARCHAR(20)
);

ALTER TABLE report ADD COLUMN hardwaredb_systems_id INT(11);

CREATE INDEX report_idx_id02 ON report (id);

CREATE INDEX report_idx_machine_name02 ON report (machine_name);

ALTER TABLE reportcomment ADD COLUMN succession INT(10);

DROP INDEX reportgroup_idx_report_id_repo;

DROP INDEX reportgrouparbitrary_idx_report_id_reportgrouparbi;

DROP INDEX reportgrouptestrun_idx_report_id_reportgrouptest;

DROP INDEX reportsection_idx_report_id_re;

ALTER TABLE reportsection ADD COLUMN bios TEXT;

CREATE INDEX suite_idx_name02 ON suite (name);


COMMIT;

