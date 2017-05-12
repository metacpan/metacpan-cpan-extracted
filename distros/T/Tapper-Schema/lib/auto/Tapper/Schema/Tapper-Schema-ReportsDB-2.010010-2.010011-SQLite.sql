-- Convert schema '/2home/ss5/local/projects/Tapper/src/Tapper-Schema/upgrades/Tapper-Schema-ReportsDB-2.010010-SQLite.sql' to '/2home/ss5/local/projects/Tapper/src/Tapper-Schema/upgrades/Tapper-Schema-ReportsDB-2.010011-SQLite.sql':

BEGIN;


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
INSERT INTO reportcomment SELECT id, report_id, user_id, comment, created_at, updated_at FROM reportcomment_temp_alter;
DROP TABLE reportcomment_temp_alter;

ALTER TABLE reportfile ADD COLUMN created_at DATETIME NOT NULL;
ALTER TABLE reportfile ADD COLUMN updated_at DATETIME NOT NULL;






COMMIT;
