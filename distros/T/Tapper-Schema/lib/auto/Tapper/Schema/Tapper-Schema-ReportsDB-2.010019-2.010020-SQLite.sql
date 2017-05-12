-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010019-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010020-SQLite.sql':

BEGIN;

CREATE INDEX report_idx_id_report_report ON report (id);


DROP INDEX reportgroup_idx_report_id_repo;
CREATE TEMPORARY TABLE reportgrouparbitrary_temp_alter (
  arbitrary_id VARCHAR(255) NOT NULL,
  report_id INT(11) NOT NULL,
  primaryreport INT(11),
  PRIMARY KEY (arbitrary_id, report_id)
);
INSERT INTO reportgrouparbitrary_temp_alter SELECT arbitrary_id, report_id, primaryreport FROM reportgrouparbitrary;
DROP TABLE reportgrouparbitrary;
CREATE TABLE reportgrouparbitrary (
  arbitrary_id VARCHAR(255) NOT NULL,
  report_id INT(11) NOT NULL,
  primaryreport INT(11),
  PRIMARY KEY (arbitrary_id, report_id)
);
INSERT INTO reportgrouparbitrary SELECT arbitrary_id, report_id, primaryreport FROM reportgrouparbitrary_temp_alter;
DROP TABLE reportgrouparbitrary_temp_alter;

DROP INDEX reportgrouptestrun_idx_report_id_reportgrouptest;
DROP INDEX reportsection_idx_report_id_re;




COMMIT;
