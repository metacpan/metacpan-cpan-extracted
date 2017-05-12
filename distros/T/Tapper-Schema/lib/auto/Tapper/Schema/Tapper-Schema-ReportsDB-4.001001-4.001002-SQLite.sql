-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-4.001001-SQLite.sql' to 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-4.001002-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE report_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  suite_id INT(11),
  suite_version VARCHAR(255),
  reportername VARCHAR(255) DEFAULT '',
  peeraddr VARCHAR(255) DEFAULT '',
  peerport VARCHAR(255) DEFAULT '',
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
  machine_name VARCHAR(255) DEFAULT '',
  machine_description TEXT DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (suite_id) REFERENCES suite(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO report_temp_alter( id, suite_id, suite_version, reportername, peeraddr, peerport, peerhost, successgrade, reviewed_successgrade, total, failed, parse_errors, passed, skipped, todo, todo_passed, wait, exit, success_ratio, starttime_test_program, endtime_test_program, machine_name, machine_description, created_at, updated_at) SELECT id, suite_id, suite_version, reportername, peeraddr, peerport, peerhost, successgrade, reviewed_successgrade, total, failed, parse_errors, passed, skipped, todo, todo_passed, wait, exit, success_ratio, starttime_test_program, endtime_test_program, machine_name, machine_description, created_at, updated_at FROM report;

DROP TABLE report;

CREATE TABLE report (
  id INTEGER PRIMARY KEY NOT NULL,
  suite_id INT(11),
  suite_version VARCHAR(255),
  reportername VARCHAR(255) DEFAULT '',
  peeraddr VARCHAR(255) DEFAULT '',
  peerport VARCHAR(255) DEFAULT '',
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
  machine_name VARCHAR(255) DEFAULT '',
  machine_description TEXT DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (suite_id) REFERENCES suite(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX report_idx_suite_id03 ON report (suite_id);

CREATE INDEX report_idx_machine_name03 ON report (machine_name);

CREATE INDEX report_idx_created_at03 ON report (created_at);

INSERT INTO report SELECT id, suite_id, suite_version, reportername, peeraddr, peerport, peerhost, successgrade, reviewed_successgrade, total, failed, parse_errors, passed, skipped, todo, todo_passed, wait, exit, success_ratio, starttime_test_program, endtime_test_program, machine_name, machine_description, created_at, updated_at FROM report_temp_alter;

DROP TABLE report_temp_alter;

CREATE TEMPORARY TABLE reportsection_temp_alter (
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
  ram VARCHAR(255),
  uptime VARCHAR(255),
  lspci TEXT,
  lsusb TEXT,
  ticket_url VARCHAR(255),
  wiki_url VARCHAR(255),
  planning_id VARCHAR(255),
  moreinfo_url VARCHAR(255),
  tags VARCHAR(255),
  xen_changeset VARCHAR(255),
  xen_hvbits VARCHAR(255),
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

INSERT INTO reportsection_temp_alter( id, report_id, succession, name, osname, uname, flags, changeset, kernel, description, language_description, cpuinfo, bios, ram, uptime, lspci, lsusb, ticket_url, wiki_url, planning_id, moreinfo_url, tags, xen_changeset, xen_hvbits, xen_dom0_kernel, xen_base_os_description, xen_guest_description, xen_guest_flags, xen_version, xen_guest_test, xen_guest_start, kvm_kernel, kvm_base_os_description, kvm_guest_description, kvm_module_version, kvm_userspace_version, kvm_guest_flags, kvm_guest_test, kvm_guest_start, simnow_svn_version, simnow_version, simnow_svn_repository, simnow_device_interface_version, simnow_bsd_file, simnow_image_file) SELECT id, report_id, succession, name, osname, uname, flags, changeset, kernel, description, language_description, cpuinfo, bios, ram, uptime, lspci, lsusb, ticket_url, wiki_url, planning_id, moreinfo_url, tags, xen_changeset, xen_hvbits, xen_dom0_kernel, xen_base_os_description, xen_guest_description, xen_guest_flags, xen_version, xen_guest_test, xen_guest_start, kvm_kernel, kvm_base_os_description, kvm_guest_description, kvm_module_version, kvm_userspace_version, kvm_guest_flags, kvm_guest_test, kvm_guest_start, simnow_svn_version, simnow_version, simnow_svn_repository, simnow_device_interface_version, simnow_bsd_file, simnow_image_file FROM reportsection;

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
  ram VARCHAR(255),
  uptime VARCHAR(255),
  lspci TEXT,
  lsusb TEXT,
  ticket_url VARCHAR(255),
  wiki_url VARCHAR(255),
  planning_id VARCHAR(255),
  moreinfo_url VARCHAR(255),
  tags VARCHAR(255),
  xen_changeset VARCHAR(255),
  xen_hvbits VARCHAR(255),
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

CREATE INDEX reportsection_idx_report_id03 ON reportsection (report_id);

INSERT INTO reportsection SELECT id, report_id, succession, name, osname, uname, flags, changeset, kernel, description, language_description, cpuinfo, bios, ram, uptime, lspci, lsusb, ticket_url, wiki_url, planning_id, moreinfo_url, tags, xen_changeset, xen_hvbits, xen_dom0_kernel, xen_base_os_description, xen_guest_description, xen_guest_flags, xen_version, xen_guest_test, xen_guest_start, kvm_kernel, kvm_base_os_description, kvm_guest_description, kvm_module_version, kvm_userspace_version, kvm_guest_flags, kvm_guest_test, kvm_guest_start, simnow_svn_version, simnow_version, simnow_svn_repository, simnow_device_interface_version, simnow_bsd_file, simnow_image_file FROM reportsection_temp_alter;

DROP TABLE reportsection_temp_alter;

CREATE TEMPORARY TABLE reporttopic_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  name VARCHAR(255) DEFAULT '',
  details TEXT NOT NULL DEFAULT '',
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE ON UPDATE CASCADE
);

INSERT INTO reporttopic_temp_alter( id, report_id, name, details) SELECT id, report_id, name, details FROM reporttopic;

DROP TABLE reporttopic;

CREATE TABLE reporttopic (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  name VARCHAR(255) DEFAULT '',
  details TEXT NOT NULL DEFAULT '',
  FOREIGN KEY (report_id) REFERENCES report(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX reporttopic_idx_report_id03 ON reporttopic (report_id);

INSERT INTO reporttopic SELECT id, report_id, name, details FROM reporttopic_temp_alter;

DROP TABLE reporttopic_temp_alter;

CREATE TEMPORARY TABLE suite_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL,
  description TEXT NOT NULL
);

INSERT INTO suite_temp_alter( id, name, type, description) SELECT id, name, type, description FROM suite;

DROP TABLE suite;

CREATE TABLE suite (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL,
  description TEXT NOT NULL
);

CREATE INDEX suite_idx_name03 ON suite (name);

INSERT INTO suite SELECT id, name, type, description FROM suite_temp_alter;

DROP TABLE suite_temp_alter;


COMMIT;

