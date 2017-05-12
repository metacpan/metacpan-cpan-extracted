-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Mon Sep 24 13:07:00 2012
-- 

BEGIN TRANSACTION;

--
-- Table: notification_event
--
DROP TABLE notification_event;

CREATE TABLE notification_event (
  id INTEGER PRIMARY KEY NOT NULL,
  message VARCHAR(255),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

--
-- Table: owner
--
DROP TABLE owner;

CREATE TABLE owner (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);

CREATE UNIQUE INDEX unique_login ON owner (login);

--
-- Table: reportgrouptestrunstats
--
DROP TABLE reportgrouptestrunstats;

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
  flags VARCHAR(255),
  changeset VARCHAR(255),
  kernel VARCHAR(255),
  description VARCHAR(255),
  language_description TEXT,
  cpuinfo TEXT,
  bios TEXT,
  ram VARCHAR(50),
  uptime VARCHAR(50),
  lspci TEXT,
  lsusb TEXT,
  ticket_url VARCHAR(255),
  wiki_url VARCHAR(255),
  planning_id VARCHAR(255),
  moreinfo_url VARCHAR(255),
  tags VARCHAR(255),
  xen_changeset VARCHAR(255),
  xen_hvbits VARCHAR(10),
  xen_dom0_kernel TEXT,
  xen_base_os_description TEXT,
  xen_guest_description TEXT,
  xen_guest_flags VARCHAR(255),
  xen_version VARCHAR(255),
  xen_guest_test VARCHAR(255),
  xen_guest_start VARCHAR(255),
  kvm_kernel TEXT,
  kvm_base_os_description TEXT,
  kvm_guest_description TEXT,
  kvm_module_version VARCHAR(255),
  kvm_userspace_version VARCHAR(255),
  kvm_guest_flags VARCHAR(255),
  kvm_guest_test VARCHAR(255),
  kvm_guest_start VARCHAR(255),
  simnow_svn_version VARCHAR(255),
  simnow_version VARCHAR(255),
  simnow_svn_repository VARCHAR(255),
  simnow_device_interface_version VARCHAR(255),
  simnow_bsd_file VARCHAR(255),
  simnow_image_file VARCHAR(255)
);

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

CREATE INDEX suite_idx_name ON suite (name);

--
-- Table: contact
--
DROP TABLE contact;

CREATE TABLE contact (
  id INTEGER PRIMARY KEY NOT NULL,
  owner_id INT(11) NOT NULL,
  address VARCHAR(255) NOT NULL,
  protocol VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX contact_idx_owner_id ON contact (owner_id);

--
-- Table: notification
--
DROP TABLE notification;

CREATE TABLE notification (
  id INTEGER PRIMARY KEY NOT NULL,
  owner_id INT(11),
  persist INT(1),
  event VARCHAR(255) NOT NULL,
  filter TEXT NOT NULL,
  comment VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (owner_id) REFERENCES owner(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX notification_idx_owner_id ON notification (owner_id);

--
-- Table: report
--
DROP TABLE report;

CREATE TABLE report (
  id INTEGER PRIMARY KEY NOT NULL,
  suite_id INT(11),
  suite_version VARCHAR(11),
  reportername VARCHAR(100) DEFAULT '',
  peeraddr VARCHAR(20) DEFAULT '',
  peerport VARCHAR(20) DEFAULT '',
  peerhost VARCHAR(255) DEFAULT '',
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
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (suite_id) REFERENCES suite(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX report_idx_suite_id ON report (suite_id);

CREATE INDEX report_idx_machine_name ON report (machine_name);

--
-- Table: reportfile
--
DROP TABLE reportfile;

CREATE TABLE reportfile (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  filename VARCHAR(255) DEFAULT '',
  contenttype VARCHAR(255) DEFAULT '',
  filecontent LONGBLOB NOT NULL DEFAULT '',
  is_compressed INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX reportfile_idx_report_id ON reportfile (report_id);

--
-- Table: reportgrouparbitrary
--
DROP TABLE reportgrouparbitrary;

CREATE TABLE reportgrouparbitrary (
  arbitrary_id VARCHAR(255) NOT NULL,
  report_id INT(11) NOT NULL,
  primaryreport INT(11),
  owner VARCHAR(255),
  PRIMARY KEY (arbitrary_id, report_id),
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE
);

CREATE INDEX reportgrouparbitrary_idx_report_id ON reportgrouparbitrary (report_id);

--
-- Table: reportgrouptestrun
--
DROP TABLE reportgrouptestrun;

CREATE TABLE reportgrouptestrun (
  testrun_id INT(11) NOT NULL,
  report_id INT(11) NOT NULL,
  primaryreport INT(11),
  owner VARCHAR(255),
  PRIMARY KEY (testrun_id, report_id),
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE
);

CREATE INDEX reportgrouptestrun_idx_report_id ON reportgrouptestrun (report_id);

--
-- Table: reporttopic
--
DROP TABLE reporttopic;

CREATE TABLE reporttopic (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  name VARCHAR(50) DEFAULT '',
  details TEXT NOT NULL DEFAULT '',
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX reporttopic_idx_report_id ON reporttopic (report_id);

--
-- Table: tap
--
DROP TABLE tap;

CREATE TABLE tap (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  tap LONGBLOB NOT NULL DEFAULT '',
  tap_is_archive INT(11),
  tapdom LONGBLOB DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE
);

CREATE INDEX tap_idx_report_id ON tap (report_id);

--
-- Table: reportcomment
--
DROP TABLE reportcomment;

CREATE TABLE reportcomment (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  owner_id INT(11),
  succession INT(10),
  comment TEXT NOT NULL DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (owner_id) REFERENCES owner(id),
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX reportcomment_idx_owner_id ON reportcomment (owner_id);

CREATE INDEX reportcomment_idx_report_id ON reportcomment (report_id);

--
-- View: view_testrun_overview_reports
--
DROP VIEW IF EXISTS view_testrun_overview_reports;

CREATE VIEW view_testrun_overview_reports AS
    select rgts.testrun_id    as rgt_testrun_id,        max(rgt.report_id) as primary_report_id,        rgts.success_ratio as rgts_success_ratio from reportgrouptestrun rgt, reportgrouptestrunstats rgts where rgt.testrun_id=rgts.testrun_id group by rgt.testrun_id;

--
-- View: view_testrun_overview
--
DROP VIEW IF EXISTS view_testrun_overview;

CREATE VIEW view_testrun_overview AS
    select vtor.*,        r.machine_name,        r.created_at,        r.suite_id,        s.name as suite_name from view_testrun_overview_reports vtor,      report r,      suite s where vtor.primary_report_id=r.id and       r.suite_id=s.id;

COMMIT;
