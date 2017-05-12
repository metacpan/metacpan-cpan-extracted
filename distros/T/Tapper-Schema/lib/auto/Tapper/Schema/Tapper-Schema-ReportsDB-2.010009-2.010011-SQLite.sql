-- Convert schema '/var/tmp/Tapper-Schema-ReportsDB-2.010009-SQLite.sql' to '/var/tmp/Tapper-Schema-ReportsDB-2.010011-SQLite.sql':

BEGIN;

CREATE INDEX report_idx_suite_id_report_rep ON report (suite_id);
CREATE TEMPORARY TABLE reportcomment_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  user_id INT(11),
  comment TEXT NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
INSERT INTO reportcomment_temp_alter SELECT id, report_id, user_id, comment, created_at, updated_at FROM reportcomment;
DROP TABLE reportcomment;
CREATE TABLE reportcomment (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  user_id INT(11),
  comment TEXT NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
CREATE INDEX reportcomment_idx_report_id_re_reportcommen ON reportcomment (report_id);
CREATE INDEX reportcomment_idx_user_id_repo_reportcommen ON reportcomment (user_id);
INSERT INTO reportcomment SELECT id, report_id, user_id, comment, created_at, updated_at FROM reportcomment_temp_alter;
DROP TABLE reportcomment_temp_alter;

ALTER TABLE reportfile ADD COLUMN created_at DATETIME NOT NULL;
ALTER TABLE reportfile ADD COLUMN updated_at DATETIME NOT NULL;
CREATE INDEX reportfile_idx_report_id_repor_reportfil ON reportfile (report_id);
CREATE INDEX reportgroup_idx_report_id_repo_reportgrou ON reportgroup (report_id);
CREATE INDEX reportsection_idx_report_id_re_reportsectio ON reportsection (report_id);
CREATE INDEX reporttopic_idx_report_id_repo_reporttopi ON reporttopic (report_id);



COMMIT;
