-- Convert schema 'upgrades/Tapper-Schema-ReportsDB-2.010021-SQLite.sql' to 'upgrades/Tapper-Schema-ReportsDB-2.010022-SQLite.sql':;

BEGIN;

CREATE TEMPORARY TABLE reportsection_temp_alter (
  id INTEGER PRIMARY KEY NOT NULL,
  report_id INT(11) NOT NULL,
  succession INT(10),
  name VARCHAR(255),
  osname VARCHAR(255),
  uname VARCHAR(255),
  language_description TEXT,
  cpuinfo TEXT,
  ram VARCHAR(50),
  uptime VARCHAR(50),
  lspci TEXT,
  lsusb TEXT,
  flags VARCHAR(255),
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
  kvm_guest_start VARCHAR(255)
);

INSERT INTO reportsection_temp_alter SELECT id, report_id, succession, name, osname, uname, language_description, cpuinfo, ram, uptime, lspci, lsusb, flags, xen_changeset, xen_hvbits, xen_dom0_kernel, xen_base_os_description, xen_guest_description, xen_guest_flags, xen_version, xen_guest_test, xen_guest_start, kvm_kernel, kvm_base_os_description, kvm_guest_description, kvm_module_version, kvm_userspace_version, kvm_guest_flags, kvm_guest_test, kvm_guest_start FROM reportsection;

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
  uptime VARCHAR(50),
  lspci TEXT,
  lsusb TEXT,
  flags VARCHAR(255),
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
  kvm_guest_start VARCHAR(255)
);

CREATE INDEX reportsection_idx_report_id_re_reportsectio ON reportsection (report_id);

INSERT INTO reportsection SELECT id, report_id, succession, name, osname, uname, language_description, cpuinfo, ram, uptime, lspci, lsusb, flags, xen_changeset, xen_hvbits, xen_dom0_kernel, xen_base_os_description, xen_guest_description, xen_guest_flags, xen_version, xen_guest_test, xen_guest_start, kvm_kernel, kvm_base_os_description, kvm_guest_description, kvm_module_version, kvm_userspace_version, kvm_guest_flags, kvm_guest_test, kvm_guest_start FROM reportsection_temp_alter;

DROP TABLE reportsection_temp_alter;


COMMIT;

