-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Thu Mar 10 12:06:40 2016
-- 

BEGIN TRANSACTION;

--
-- Table: bench_additional_types
--
DROP TABLE bench_additional_types;

CREATE TABLE bench_additional_types (
  bench_additional_type_id INTEGER PRIMARY KEY NOT NULL,
  bench_additional_type VARCHAR(767) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX ux_bench_additional_types_01 ON bench_additional_types (bench_additional_type);

--
-- Table: bench_subsume_types
--
DROP TABLE bench_subsume_types;

CREATE TABLE bench_subsume_types (
  bench_subsume_type_id INTEGER PRIMARY KEY NOT NULL,
  bench_subsume_type VARCHAR(32) NOT NULL,
  bench_subsume_type_rank TINYINT(4) NOT NULL,
  datetime_strftime_pattern VARCHAR(32),
  created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX ux_bench_subsume_types_01 ON bench_subsume_types (bench_subsume_type);

--
-- Table: bench_units
--
DROP TABLE bench_units;

CREATE TABLE bench_units (
  bench_unit_id INTEGER PRIMARY KEY NOT NULL,
  bench_unit VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX ux_bench_units_01 ON bench_units (bench_unit);

--
-- Table: chart_axis_types
--
DROP TABLE chart_axis_types;

CREATE TABLE chart_axis_types (
  chart_axis_type_id INTEGER PRIMARY KEY NOT NULL,
  chart_axis_type_name VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX ux_chart_axis_types_01 ON chart_axis_types (chart_axis_type_name);

--
-- Table: chart_tags
--
DROP TABLE chart_tags;

CREATE TABLE chart_tags (
  chart_tag_id INTEGER PRIMARY KEY NOT NULL,
  chart_tag VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX ux_chart_tags_01 ON chart_tags (chart_tag);

--
-- Table: chart_tiny_urls
--
DROP TABLE chart_tiny_urls;

CREATE TABLE chart_tiny_urls (
  chart_tiny_url_id INTEGER PRIMARY KEY NOT NULL,
  visit_count INT(12) NOT NULL DEFAULT 0,
  last_visited TIMESTAMP,
  created_at TIMESTAMP NOT NULL
);

--
-- Table: chart_types
--
DROP TABLE chart_types;

CREATE TABLE chart_types (
  chart_type_id INTEGER PRIMARY KEY NOT NULL,
  chart_type_name VARCHAR(64) NOT NULL,
  chart_type_description VARCHAR(256) NOT NULL,
  chart_type_flot_name VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX ux_chart_types_01 ON chart_types (chart_type_name);

CREATE UNIQUE INDEX ux_chart_types_02 ON chart_types (chart_type_flot_name);

--
-- Table: charts
--
DROP TABLE charts;

CREATE TABLE charts (
  chart_id INTEGER PRIMARY KEY NOT NULL,
  active TINYINT(4) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP
);

--
-- Table: host
--
DROP TABLE host;

CREATE TABLE host (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  comment VARCHAR(255) DEFAULT '',
  free TINYINT DEFAULT 0,
  active TINYINT DEFAULT 0,
  is_deleted TINYINT DEFAULT 0,
  pool_free INT,
  pool_id INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (pool_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX host_idx_pool_id ON host (pool_id);

CREATE UNIQUE INDEX constraint_name ON host (name);

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
  name VARCHAR(255),
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255)
);

CREATE UNIQUE INDEX unique_login ON owner (login);

--
-- Table: precondition
--
DROP TABLE precondition;

CREATE TABLE precondition (
  id INTEGER PRIMARY KEY NOT NULL,
  shortname VARCHAR(255) NOT NULL DEFAULT '',
  precondition TEXT,
  timeout INT(10)
);

--
-- Table: preconditiontype
--
DROP TABLE preconditiontype;

CREATE TABLE preconditiontype (
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);

--
-- Table: queue
--
DROP TABLE queue;

CREATE TABLE queue (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) DEFAULT '',
  priority INT(10) NOT NULL DEFAULT 0,
  runcount INT(10) NOT NULL DEFAULT 0,
  active INT(1) DEFAULT 0,
  is_deleted TINYINT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

CREATE UNIQUE INDEX unique_queue_name ON queue (name);

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

CREATE INDEX reportsection_idx_report_id ON reportsection (report_id);

--
-- Table: scenario
--
DROP TABLE scenario;

CREATE TABLE scenario (
  id INTEGER PRIMARY KEY NOT NULL,
  type VARCHAR(255) NOT NULL DEFAULT '',
  options TEXT,
  name VARCHAR(255)
);

--
-- Table: suite
--
DROP TABLE suite;

CREATE TABLE suite (
  id INTEGER PRIMARY KEY NOT NULL,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL,
  description TEXT NOT NULL
);

CREATE INDEX suite_idx_name ON suite (name);

--
-- Table: testplan_instance
--
DROP TABLE testplan_instance;

CREATE TABLE testplan_instance (
  id INTEGER PRIMARY KEY NOT NULL,
  path VARCHAR(255) DEFAULT '',
  name VARCHAR(255) DEFAULT '',
  evaluated_testplan TEXT DEFAULT '',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME
);

--
-- Table: topic
--
DROP TABLE topic;

CREATE TABLE topic (
  name VARCHAR(255) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (name)
);

--
-- Table: bench_additional_values
--
DROP TABLE bench_additional_values;

CREATE TABLE bench_additional_values (
  bench_additional_value_id INTEGER PRIMARY KEY NOT NULL,
  bench_additional_type_id SMALLINT(6) NOT NULL,
  bench_additional_value VARCHAR(767) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (bench_additional_type_id) REFERENCES bench_additional_types(bench_additional_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX bench_additional_values_idx_bench_additional_type_id ON bench_additional_values (bench_additional_type_id);

CREATE UNIQUE INDEX ux_bench_additional_values_01 ON bench_additional_values (bench_additional_type_id, bench_additional_value);

--
-- Table: benchs
--
DROP TABLE benchs;

CREATE TABLE benchs (
  bench_id INTEGER PRIMARY KEY NOT NULL,
  bench_unit_id TINYINT(4) NOT NULL,
  bench VARCHAR(767) NOT NULL,
  active TINYINT(4) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (bench_unit_id) REFERENCES bench_units(bench_unit_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX benchs_idx_bench_unit_id ON benchs (bench_unit_id);

CREATE UNIQUE INDEX ux_benchs_01 ON benchs (bench);

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
-- Table: host_feature
--
DROP TABLE host_feature;

CREATE TABLE host_feature (
  id INTEGER PRIMARY KEY NOT NULL,
  host_id INT NOT NULL,
  entry VARCHAR(255) NOT NULL,
  value VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX host_feature_idx_host_id ON host_feature (host_id);

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
-- Table: pre_precondition
--
DROP TABLE pre_precondition;

CREATE TABLE pre_precondition (
  parent_precondition_id INT(11) NOT NULL,
  child_precondition_id INT(11) NOT NULL,
  succession INT(10) NOT NULL,
  PRIMARY KEY (parent_precondition_id, child_precondition_id),
  FOREIGN KEY (child_precondition_id) REFERENCES precondition(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (parent_precondition_id) REFERENCES precondition(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX pre_precondition_idx_child_precondition_id ON pre_precondition (child_precondition_id);

CREATE INDEX pre_precondition_idx_parent_precondition_id ON pre_precondition (parent_precondition_id);

--
-- Table: report
--
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
  success_ratio VARCHAR(20),
  starttime_test_program DATETIME,
  endtime_test_program DATETIME,
  machine_name VARCHAR(255) DEFAULT '',
  machine_description TEXT DEFAULT '',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (suite_id) REFERENCES suite(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX report_idx_suite_id ON report (suite_id);

CREATE INDEX report_idx_machine_name ON report (machine_name);

CREATE INDEX report_idx_created_at ON report (created_at);

--
-- Table: chart_tag_relations
--
DROP TABLE chart_tag_relations;

CREATE TABLE chart_tag_relations (
  chart_id INT(11) NOT NULL,
  chart_tag_id SMALLINT(6) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (chart_id, chart_tag_id),
  FOREIGN KEY (chart_id) REFERENCES charts(chart_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (chart_tag_id) REFERENCES chart_tags(chart_tag_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_tag_relations_idx_chart_id ON chart_tag_relations (chart_id);

CREATE INDEX chart_tag_relations_idx_chart_tag_id ON chart_tag_relations (chart_tag_id);

--
-- Table: denied_host
--
DROP TABLE denied_host;

CREATE TABLE denied_host (
  id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (queue_id) REFERENCES queue(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX denied_host_idx_host_id ON denied_host (host_id);

CREATE INDEX denied_host_idx_queue_id ON denied_host (queue_id);

--
-- Table: queue_host
--
DROP TABLE queue_host;

CREATE TABLE queue_host (
  id INTEGER PRIMARY KEY NOT NULL,
  queue_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (queue_id) REFERENCES queue(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX queue_host_idx_host_id ON queue_host (host_id);

CREATE INDEX queue_host_idx_queue_id ON queue_host (queue_id);

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
  name VARCHAR(255) DEFAULT '',
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
-- Table: testrun
--
DROP TABLE testrun;

CREATE TABLE testrun (
  id INTEGER PRIMARY KEY NOT NULL,
  shortname VARCHAR(255) NOT NULL,
  notes TEXT,
  topic_name VARCHAR(255) NOT NULL,
  starttime_earliest TIMESTAMP,
  starttime_testrun TIMESTAMP,
  starttime_test_program TIMESTAMP,
  endtime_test_program TIMESTAMP,
  owner_id INT(11),
  testplan_id INT(11),
  wait_after_tests TINYINT(1) DEFAULT 0,
  rerun_on_error TINYINT(1) DEFAULT 0,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (owner_id) REFERENCES owner(id),
  FOREIGN KEY (testplan_id) REFERENCES testplan_instance(id) ON UPDATE CASCADE
);

CREATE INDEX testrun_idx_owner_id ON testrun (owner_id);

CREATE INDEX testrun_idx_testplan_id ON testrun (testplan_id);

CREATE INDEX testrun_idx_created_at ON testrun (created_at);

--
-- Table: bench_additional_type_relations
--
DROP TABLE bench_additional_type_relations;

CREATE TABLE bench_additional_type_relations (
  bench_id INT(12) NOT NULL,
  bench_additional_type_id SMALLINT(6) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (bench_id, bench_additional_type_id),
  FOREIGN KEY (bench_id) REFERENCES benchs(bench_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (bench_additional_type_id) REFERENCES bench_additional_types(bench_additional_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX bench_additional_type_relations_idx_bench_id ON bench_additional_type_relations (bench_id);

CREATE INDEX bench_additional_type_relations_idx_bench_additional_type_id ON bench_additional_type_relations (bench_additional_type_id);

--
-- Table: bench_values
--
DROP TABLE bench_values;

CREATE TABLE bench_values (
  bench_value_id INTEGER PRIMARY KEY NOT NULL,
  bench_id INT(11) NOT NULL,
  bench_subsume_type_id SMALLINT(6) NOT NULL,
  bench_value VARCHAR(767) NOT NULL,
  active TINYINT(4) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (bench_id) REFERENCES benchs(bench_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (bench_subsume_type_id) REFERENCES bench_subsume_types(bench_subsume_type_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX bench_values_idx_bench_id ON bench_values (bench_id);

CREATE INDEX bench_values_idx_bench_subsume_type_id ON bench_values (bench_subsume_type_id);

--
-- Table: chart_versions
--
DROP TABLE chart_versions;

CREATE TABLE chart_versions (
  chart_version_id INTEGER PRIMARY KEY NOT NULL,
  chart_id INT(11) NOT NULL,
  chart_type_id TINYINT(4) NOT NULL,
  chart_axis_type_x_id TINYINT(4) NOT NULL,
  chart_axis_type_y_id TINYINT(4) NOT NULL,
  chart_version TINYINT(4) NOT NULL,
  chart_name VARCHAR(64) NOT NULL,
  order_by_x_axis TINYINT(4) NOT NULL,
  order_by_y_axis TINYINT(4) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP,
  FOREIGN KEY (chart_id) REFERENCES charts(chart_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (chart_axis_type_x_id) REFERENCES chart_axis_types(chart_axis_type_id),
  FOREIGN KEY (chart_axis_type_y_id) REFERENCES chart_axis_types(chart_axis_type_id),
  FOREIGN KEY (chart_type_id) REFERENCES chart_types(chart_type_id)
);

CREATE INDEX chart_versions_idx_chart_id ON chart_versions (chart_id);

CREATE INDEX chart_versions_idx_chart_axis_type_x_id ON chart_versions (chart_axis_type_x_id);

CREATE INDEX chart_versions_idx_chart_axis_type_y_id ON chart_versions (chart_axis_type_y_id);

CREATE INDEX chart_versions_idx_chart_type_id ON chart_versions (chart_type_id);

CREATE UNIQUE INDEX ux_chart_versions_01 ON chart_versions (chart_id, chart_version);

--
-- Table: message
--
DROP TABLE message;

CREATE TABLE message (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11),
  message VARCHAR(65000),
  type VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX message_idx_testrun_id ON message (testrun_id);

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
-- Table: state
--
DROP TABLE state;

CREATE TABLE state (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  state VARCHAR(65000),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE
);

CREATE INDEX state_idx_testrun_id ON state (testrun_id);

CREATE UNIQUE INDEX unique_testrun_id ON state (testrun_id);

--
-- Table: testrun_requested_feature
--
DROP TABLE testrun_requested_feature;

CREATE TABLE testrun_requested_feature (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  feature VARCHAR(255) DEFAULT '',
  FOREIGN KEY (testrun_id) REFERENCES testrun(id)
);

CREATE INDEX testrun_requested_feature_idx_testrun_id ON testrun_requested_feature (testrun_id);

--
-- Table: bench_backup_values
--
DROP TABLE bench_backup_values;

CREATE TABLE bench_backup_values (
  bench_backup_value_id INTEGER PRIMARY KEY NOT NULL,
  bench_value_id INT(11) NOT NULL,
  bench_id INT(11) NOT NULL,
  bench_subsume_type_id SMALLINT(6) NOT NULL,
  bench_value VARCHAR(767) NOT NULL,
  active TINYINT(4) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (bench_id) REFERENCES benchs(bench_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (bench_subsume_type_id) REFERENCES bench_subsume_types(bench_subsume_type_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (bench_value_id) REFERENCES bench_values(bench_value_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX bench_backup_values_idx_bench_id ON bench_backup_values (bench_id);

CREATE INDEX bench_backup_values_idx_bench_subsume_type_id ON bench_backup_values (bench_subsume_type_id);

CREATE INDEX bench_backup_values_idx_bench_value_id ON bench_backup_values (bench_value_id);

--
-- Table: chart_lines
--
DROP TABLE chart_lines;

CREATE TABLE chart_lines (
  chart_line_id INTEGER PRIMARY KEY NOT NULL,
  chart_version_id INT(11) NOT NULL,
  chart_line_name VARCHAR(128) NOT NULL,
  chart_axis_x_column_format VARCHAR(64) NOT NULL,
  chart_axis_y_column_format VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (chart_version_id) REFERENCES chart_versions(chart_version_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_lines_idx_chart_version_id ON chart_lines (chart_version_id);

CREATE UNIQUE INDEX ux_chart_lines_01 ON chart_lines (chart_version_id, chart_line_name);

--
-- Table: chart_markings
--
DROP TABLE chart_markings;

CREATE TABLE chart_markings (
  chart_marking_id INTEGER PRIMARY KEY NOT NULL,
  chart_version_id INT(11) NOT NULL,
  chart_marking_name VARCHAR(128) NOT NULL,
  chart_marking_color CHAR(6) NOT NULL,
  chart_marking_x_from VARCHAR(512),
  chart_marking_x_to VARCHAR(512),
  chart_marking_x_format VARCHAR(64),
  chart_marking_y_from VARCHAR(512),
  chart_marking_y_to VARCHAR(512),
  chart_marking_y_format VARCHAR(64),
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (chart_version_id) REFERENCES chart_versions(chart_version_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_markings_idx_chart_version_id ON chart_markings (chart_version_id);

--
-- Table: scenario_element
--
DROP TABLE scenario_element;

CREATE TABLE scenario_element (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  scenario_id INT(11) NOT NULL,
  is_fitted INT(1) NOT NULL DEFAULT 0,
  FOREIGN KEY (scenario_id) REFERENCES scenario(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE
);

CREATE INDEX scenario_element_idx_scenario_id ON scenario_element (scenario_id);

CREATE INDEX scenario_element_idx_testrun_id ON scenario_element (testrun_id);

--
-- Table: testrun_precondition
--
DROP TABLE testrun_precondition;

CREATE TABLE testrun_precondition (
  testrun_id INT(11) NOT NULL,
  precondition_id INT(11) NOT NULL,
  succession INT(10),
  PRIMARY KEY (testrun_id, precondition_id),
  FOREIGN KEY (precondition_id) REFERENCES precondition(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX testrun_precondition_idx_precondition_id ON testrun_precondition (precondition_id);

CREATE INDEX testrun_precondition_idx_testrun_id ON testrun_precondition (testrun_id);

--
-- Table: testrun_requested_host
--
DROP TABLE testrun_requested_host;

CREATE TABLE testrun_requested_host (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  host_id INT(11) NOT NULL,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX testrun_requested_host_idx_host_id ON testrun_requested_host (host_id);

CREATE INDEX testrun_requested_host_idx_testrun_id ON testrun_requested_host (testrun_id);

--
-- Table: chart_line_additionals
--
DROP TABLE chart_line_additionals;

CREATE TABLE chart_line_additionals (
  chart_line_id INT(11) NOT NULL,
  chart_line_additional_column VARCHAR(512) NOT NULL,
  chart_line_additional_url VARCHAR(1024),
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (chart_line_id, chart_line_additional_column),
  FOREIGN KEY (chart_line_id) REFERENCES chart_lines(chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_line_additionals_idx_chart_line_id ON chart_line_additionals (chart_line_id);

--
-- Table: chart_line_axis_elements
--
DROP TABLE chart_line_axis_elements;

CREATE TABLE chart_line_axis_elements (
  chart_line_axis_element_id INTEGER PRIMARY KEY NOT NULL,
  chart_line_id INT(11) NOT NULL,
  chart_line_axis CHAR(1) NOT NULL,
  chart_line_axis_element_number TINYINT(4) NOT NULL,
  FOREIGN KEY (chart_line_id) REFERENCES chart_lines(chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_line_axis_elements_idx_chart_line_id ON chart_line_axis_elements (chart_line_id);

CREATE UNIQUE INDEX ux_chart_line_axis_elements_01 ON chart_line_axis_elements (chart_line_id, chart_line_axis, chart_line_axis_element_number);

--
-- Table: chart_line_restrictions
--
DROP TABLE chart_line_restrictions;

CREATE TABLE chart_line_restrictions (
  chart_line_restriction_id INTEGER PRIMARY KEY NOT NULL,
  chart_line_id INT(11) NOT NULL,
  chart_line_restriction_operator VARCHAR(4) NOT NULL,
  chart_line_restriction_column VARCHAR(512) NOT NULL,
  is_template_restriction TINYINT(3) NOT NULL,
  is_numeric_restriction TINYINT(3) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  FOREIGN KEY (chart_line_id) REFERENCES chart_lines(chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_line_restrictions_idx_chart_line_id ON chart_line_restrictions (chart_line_id);

--
-- Table: testrun_scheduling
--
DROP TABLE testrun_scheduling;

CREATE TABLE testrun_scheduling (
  id INTEGER PRIMARY KEY NOT NULL,
  testrun_id INT(11) NOT NULL,
  queue_id INT(11) DEFAULT 0,
  host_id INT(11),
  prioqueue_seq INT(11),
  status VARCHAR(255) DEFAULT 'prepare',
  auto_rerun TINYINT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (host_id) REFERENCES host(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (queue_id) REFERENCES queue(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE
);

CREATE INDEX testrun_scheduling_idx_host_id ON testrun_scheduling (host_id);

CREATE INDEX testrun_scheduling_idx_queue_id ON testrun_scheduling (queue_id);

CREATE INDEX testrun_scheduling_idx_testrun_id ON testrun_scheduling (testrun_id);

CREATE INDEX testrun_scheduling_idx_created_at ON testrun_scheduling (created_at);

CREATE INDEX testrun_scheduling_idx_status ON testrun_scheduling (status);

--
-- Table: bench_additional_relations
--
DROP TABLE bench_additional_relations;

CREATE TABLE bench_additional_relations (
  bench_value_id INT(12) NOT NULL,
  bench_additional_value_id INT(12) NOT NULL,
  active TINYINT(4) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (bench_value_id, bench_additional_value_id),
  FOREIGN KEY (bench_additional_value_id) REFERENCES bench_additional_values(bench_additional_value_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (bench_value_id) REFERENCES bench_values(bench_value_id)
);

CREATE INDEX bench_additional_relations_idx_bench_additional_value_id ON bench_additional_relations (bench_additional_value_id);

CREATE INDEX bench_additional_relations_idx_bench_value_id ON bench_additional_relations (bench_value_id);

--
-- Table: chart_line_axis_columns
--
DROP TABLE chart_line_axis_columns;

CREATE TABLE chart_line_axis_columns (
  chart_line_axis_element_id INTEGER PRIMARY KEY NOT NULL,
  chart_line_axis_column VARCHAR(512) NOT NULL,
  FOREIGN KEY (chart_line_axis_element_id) REFERENCES chart_line_axis_elements(chart_line_axis_element_id) ON DELETE CASCADE
);

--
-- Table: chart_line_axis_separators
--
DROP TABLE chart_line_axis_separators;

CREATE TABLE chart_line_axis_separators (
  chart_line_axis_element_id INTEGER PRIMARY KEY NOT NULL,
  chart_line_axis_separator VARCHAR(128) NOT NULL,
  FOREIGN KEY (chart_line_axis_element_id) REFERENCES chart_line_axis_elements(chart_line_axis_element_id) ON DELETE CASCADE
);

--
-- Table: chart_line_restriction_values
--
DROP TABLE chart_line_restriction_values;

CREATE TABLE chart_line_restriction_values (
  chart_line_restriction_value_id INTEGER PRIMARY KEY NOT NULL,
  chart_line_restriction_id INT(11) NOT NULL,
  chart_line_restriction_value VARCHAR(512) NOT NULL,
  FOREIGN KEY (chart_line_restriction_id) REFERENCES chart_line_restrictions(chart_line_restriction_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_line_restriction_values_idx_chart_line_restriction_id ON chart_line_restriction_values (chart_line_restriction_id);

--
-- Table: chart_tiny_url_lines
--
DROP TABLE chart_tiny_url_lines;

CREATE TABLE chart_tiny_url_lines (
  chart_tiny_url_line_id INTEGER PRIMARY KEY NOT NULL,
  chart_tiny_url_id INT(12) NOT NULL,
  chart_line_id INT(12) NOT NULL,
  FOREIGN KEY (chart_line_id) REFERENCES chart_lines(chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (chart_tiny_url_id) REFERENCES chart_tiny_urls(chart_tiny_url_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_tiny_url_lines_idx_chart_line_id ON chart_tiny_url_lines (chart_line_id);

CREATE INDEX chart_tiny_url_lines_idx_chart_tiny_url_id ON chart_tiny_url_lines (chart_tiny_url_id);

--
-- Table: bench_backkup_additional_relations
--
DROP TABLE bench_backkup_additional_relations;

CREATE TABLE bench_backkup_additional_relations (
  bench_backup_value_id INT(12) NOT NULL,
  bench_additional_value_id INT(12) NOT NULL,
  active TINYINT(4) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (bench_backup_value_id, bench_additional_value_id),
  FOREIGN KEY (bench_additional_value_id) REFERENCES bench_additional_values(bench_additional_value_id),
  FOREIGN KEY (bench_backup_value_id) REFERENCES bench_backup_values(bench_backup_value_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX bench_backkup_additional_relations_idx_bench_additional_value_id ON bench_backkup_additional_relations (bench_additional_value_id);

CREATE INDEX bench_backkup_additional_relations_idx_bench_backup_value_id ON bench_backkup_additional_relations (bench_backup_value_id);

--
-- Table: chart_tiny_url_relations
--
DROP TABLE chart_tiny_url_relations;

CREATE TABLE chart_tiny_url_relations (
  chart_tiny_url_line_id INT(12) NOT NULL,
  bench_value_id INT(12) NOT NULL,
  PRIMARY KEY (chart_tiny_url_line_id, bench_value_id),
  FOREIGN KEY (bench_value_id) REFERENCES bench_values(bench_value_id),
  FOREIGN KEY (chart_tiny_url_line_id) REFERENCES chart_tiny_url_lines(chart_tiny_url_line_id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX chart_tiny_url_relations_idx_bench_value_id ON chart_tiny_url_relations (bench_value_id);

CREATE INDEX chart_tiny_url_relations_idx_chart_tiny_url_line_id ON chart_tiny_url_relations (chart_tiny_url_line_id);

--
-- View: view_testrun_overview_reports
--
DROP VIEW IF EXISTS view_testrun_overview_reports;

CREATE VIEW view_testrun_overview_reports AS
    select   rgt.testrun_id                  as rgt_testrun_id        , max(rgt.report_id)              as primary_report_id        , rgts.success_ratio              as rgts_success_ratio from reportgrouptestrun      rgt,      reportgrouptestrunstats rgts where rgt.testrun_id=rgts.testrun_id group by rgt.testrun_id, rgts.success_ratio;

--
-- View: view_testrun_overview
--
DROP VIEW IF EXISTS view_testrun_overview;

CREATE VIEW view_testrun_overview AS
    select   vtor.primary_report_id  as vtor_primary_report_id        , vtor.rgt_testrun_id     as vtor_rgt_testrun_id        , vtor.rgts_success_ratio as vtor_rgts_success_ratio        , report.id               as report_id        , report.machine_name     as report_machine_name        , report.created_at       as report_created_at        , report.suite_id         as report_suite_id        , suite.name              as report_suite_name from view_testrun_overview_reports vtor,      report report,      suite suite where CAST(vtor.primary_report_id as UNSIGNED INTEGER)=report.id and       report.suite_id=suite.id;

COMMIT;
