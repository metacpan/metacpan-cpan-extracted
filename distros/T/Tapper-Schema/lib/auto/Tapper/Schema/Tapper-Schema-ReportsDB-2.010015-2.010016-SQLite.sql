-- Convert schema '/var/tmp/Tapper-Schema-ReportsDB-2.010015-SQLite.sql' to '/var/tmp/Tapper-Schema-ReportsDB-2.010016-SQLite.sql':

BEGIN;

CREATE TABLE reportgrouparbitrary (
  arbitrary_id VARCHAR(11) NOT NULL,
  report_id INT(11) NOT NULL,
  PRIMARY KEY (arbitrary_id, report_id)
);

CREATE INDEX reportgrouparbitrary_idx_report_id_reportgrouparbi_ ON reportgrouparbitrary (report_id);

CREATE TABLE reportgrouptestrun (
  testrun_id INT(11) NOT NULL,
  report_id INT(11) NOT NULL,
  PRIMARY KEY (testrun_id, report_id)
);

CREATE INDEX reportgrouptestrun_idx_report_id_reportgrouptest_ ON reportgrouptestrun (report_id);












COMMIT;
