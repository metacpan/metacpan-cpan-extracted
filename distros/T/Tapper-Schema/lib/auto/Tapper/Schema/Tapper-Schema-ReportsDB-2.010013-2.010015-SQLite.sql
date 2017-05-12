-- Convert schema './Tapper-Schema-ReportsDB-2.010013-SQLite.sql' to './Tapper-Schema-ReportsDB-2.010015-SQLite.sql':

BEGIN;



CREATE TEMPORARY TABLE reportfile_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  filename VARCHAR(255) DEFAULT '',
  contenttype VARCHAR(255) DEFAULT '',
  filecontent LONGBLOB NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
INSERT INTO reportfile_temp_alter SELECT id, report_id, filename, contenttype, filecontent, created_at, updated_at FROM reportfile;
DROP TABLE reportfile;
CREATE TABLE reportfile (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  filename VARCHAR(255) DEFAULT '',
  contenttype VARCHAR(255) DEFAULT '',
  filecontent LONGBLOB NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);
CREATE INDEX reportfile_idx_report_id_repor_reportfil ON reportfile (report_id);
INSERT INTO reportfile SELECT id, report_id, filename, contenttype, filecontent, created_at, updated_at FROM reportfile_temp_alter;
DROP TABLE reportfile_temp_alter;







COMMIT;
