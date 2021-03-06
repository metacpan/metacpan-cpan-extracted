-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Thu Oct 23 08:50:38 2008
-- 
BEGIN TRANSACTION;


--
-- Table: report
--
DROP TABLE report;
CREATE TABLE report (
  id INTEGER PRIMARY KEY NOT NULL,
  suite_id INT(11),
  suite_version VARCHAR(11),
  reportername VARCHAR(100) DEFAULT '',
  tap TEXT NOT NULL DEFAULT '',
  successgrade VARCHAR(10) DEFAULT '',
  reviewed_successgrade VARCHAR(10) DEFAULT '',
  total INT(10),
  failed INT(10),
  parse_errors INT(10),
  passed INT(10),
  skipped INT(10),
  todo INT(10),
  todo_passed INT(10),
  wait INT(10),
  exit INT(10),
  success_ratio VARCHAR(20),
  starttime_test_program DATETIME,
  endtime_test_program DATETIME,
  machine_name VARCHAR(50) DEFAULT '',
  machine_description TEXT DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE INDEX report_idx_suite_id_report ON report (suite_id);

--
-- Table: reportcomment
--
DROP TABLE reportcomment;
CREATE TABLE reportcomment (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  user_id INT(11),
  comment TEXT NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE INDEX reportcomment_idx_report_id_re ON reportcomment (report_id);
CREATE INDEX reportcomment_idx_user_id_repo ON reportcomment (user_id);

--
-- Table: reportfile
--
DROP TABLE reportfile;
CREATE TABLE reportfile (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  filename VARCHAR(255) DEFAULT '',
  contenttype VARCHAR(255) DEFAULT '',
  filecontent BLOB NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
);

CREATE INDEX reportfile_idx_report_id_repor ON reportfile (report_id);

--
-- Table: reportgroup
--
DROP TABLE reportgroup;
CREATE TABLE reportgroup (
  id INTEGER PRIMARY KEY NOT NULL,
  group_id INT(11) NOT NULL,
  report_id INT(11) NOT NULL
);

CREATE INDEX reportgroup_idx_report_id_repo ON reportgroup (report_id);

--
-- Table: reportsection
--
DROP TABLE reportsection;
CREATE TABLE reportsection (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  succession INT(10),
  name VARCHAR(255),
  osname VARCHAR(255),
  uname VARCHAR(255),
  language_description TEXT,
  cpuinfo TEXT,
  ram VARCHAR(50),
  lspci TEXT,
  lsusb TEXT,
  flags VARCHAR(255),
  xen_changeset VARCHAR(255),
  xen_hvbits VARCHAR(10),
  xen_dom0_kernel TEXT,
  xen_base_os_description TEXT,
  xen_guest_description TEXT,
  test_was_on_guest INT(1),
  test_was_on_hv INT(1),
  xen_guest_flags VARCHAR(255)
);

CREATE INDEX reportsection_idx_report_id_re ON reportsection (report_id);

--
-- Table: reporttopic
--
DROP TABLE reporttopic;
CREATE TABLE reporttopic (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  name VARCHAR(50) DEFAULT '',
  details TEXT NOT NULL DEFAULT ''
);

CREATE INDEX reporttopic_idx_report_id_repo ON reporttopic (report_id);

--
-- Table: suite
--
DROP TABLE suite;
CREATE TABLE suite (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  description TEXT NOT NULL
);


--
-- Table: user
--
DROP TABLE user;
CREATE TABLE user (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);


COMMIT;
