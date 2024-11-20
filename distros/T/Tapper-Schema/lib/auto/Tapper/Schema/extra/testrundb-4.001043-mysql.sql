--
-- Created by SQL::Translator::Producer::MySQL
-- Created on Thu Mar 10 12:06:40 2016
--
SET foreign_key_checks=0;

DROP TABLE IF EXISTS chart_axis_types;

--
-- Table: chart_axis_types
--
CREATE TABLE chart_axis_types (
  chart_axis_type_id TINYINT(4) unsigned NOT NULL auto_increment,
  chart_axis_type_name VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (chart_axis_type_id),
  UNIQUE ux_chart_axis_types_01 (chart_axis_type_name)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_tags;

--
-- Table: chart_tags
--
CREATE TABLE chart_tags (
  chart_tag_id SMALLINT(6) unsigned NOT NULL auto_increment,
  chart_tag VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (chart_tag_id),
  UNIQUE ux_chart_tags_01 (chart_tag)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_tiny_urls;

--
-- Table: chart_tiny_urls
--
CREATE TABLE chart_tiny_urls (
  chart_tiny_url_id integer(12) unsigned NOT NULL auto_increment,
  visit_count integer(12) unsigned NOT NULL DEFAULT 0,
  last_visited TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (chart_tiny_url_id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_types;

--
-- Table: chart_types
--
CREATE TABLE chart_types (
  chart_type_id TINYINT(4) unsigned NOT NULL auto_increment,
  chart_type_name VARCHAR(64) NOT NULL,
  chart_type_description text NOT NULL,
  chart_type_flot_name VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  PRIMARY KEY (chart_type_id),
  UNIQUE ux_chart_types_01 (chart_type_name),
  UNIQUE ux_chart_types_02 (chart_type_flot_name)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS charts;

--
-- Table: charts
--
CREATE TABLE charts (
  chart_id integer(11) unsigned NOT NULL auto_increment,
  active TINYINT(4) unsigned NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NULL,
  PRIMARY KEY (chart_id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS host;

--
-- Table: host
--
CREATE TABLE host (
  id integer(11) NOT NULL auto_increment,
  name VARCHAR(255) NULL DEFAULT '',
  comment VARCHAR(255) NULL DEFAULT '',
  free TINYINT NULL DEFAULT 0,
  active TINYINT NULL DEFAULT 0,
  is_deleted TINYINT NULL DEFAULT 0,
  pool_free integer NULL,
  pool_id integer NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  INDEX host_idx_pool_id (pool_id),
  PRIMARY KEY (id),
  UNIQUE constraint_name (name),
  CONSTRAINT host_fk_pool_id FOREIGN KEY (pool_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS notification_event;

--
-- Table: notification_event
--
CREATE TABLE notification_event (
  id integer(11) NOT NULL auto_increment,
  message VARCHAR(255) NULL,
  type VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS owner;

--
-- Table: owner
--
CREATE TABLE owner (
  id integer(11) NOT NULL auto_increment,
  name VARCHAR(255) NULL,
  login VARCHAR(255) NOT NULL,
  password VARCHAR(255) NULL,
  PRIMARY KEY (id),
  UNIQUE unique_login (login)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS precondition;

--
-- Table: precondition
--
CREATE TABLE precondition (
  id integer(11) NOT NULL auto_increment,
  shortname VARCHAR(255) NOT NULL DEFAULT '',
  precondition text NULL,
  timeout integer(10) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4;

DROP TABLE IF EXISTS preconditiontype;

--
-- Table: preconditiontype
--
CREATE TABLE preconditiontype (
  name VARCHAR(255) NOT NULL,
  description text NOT NULL DEFAULT '',
  PRIMARY KEY (name)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS queue;

--
-- Table: queue
--
CREATE TABLE queue (
  id integer(11) NOT NULL auto_increment,
  name VARCHAR(255) NULL DEFAULT '',
  priority integer(10) NOT NULL DEFAULT 0,
  runcount integer(10) NOT NULL DEFAULT 0,
  active integer(1) NULL DEFAULT 0,
  is_deleted TINYINT NULL DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  PRIMARY KEY (id),
  UNIQUE unique_queue_name (name)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS reportgrouptestrunstats;

--
-- Table: reportgrouptestrunstats
--
CREATE TABLE reportgrouptestrunstats (
  testrun_id integer(11) NOT NULL,
  total integer(10) NULL,
  failed integer(10) NULL,
  passed integer(10) NULL,
  parse_errors integer(10) NULL,
  skipped integer(10) NULL,
  todo integer(10) NULL,
  todo_passed integer(10) NULL,
  success_ratio VARCHAR(20) NULL,
  PRIMARY KEY (testrun_id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS reportsection;

--
-- Table: reportsection
--
CREATE TABLE reportsection (
  id integer(11) NOT NULL auto_increment,
  report_id integer(11) NOT NULL,
  succession integer(10) NULL,
  name VARCHAR(255) NULL,
  osname VARCHAR(255) NULL,
  uname VARCHAR(255) NULL,
  flags VARCHAR(255) NULL,
  changeset VARCHAR(255) NULL,
  kernel VARCHAR(255) NULL,
  description VARCHAR(255) NULL,
  language_description text NULL,
  cpuinfo text NULL,
  bios text NULL,
  ram VARCHAR(255) NULL,
  uptime VARCHAR(255) NULL,
  lspci text NULL,
  lsusb text NULL,
  ticket_url VARCHAR(255) NULL,
  wiki_url VARCHAR(255) NULL,
  planning_id VARCHAR(255) NULL,
  moreinfo_url VARCHAR(255) NULL,
  tags VARCHAR(255) NULL,
  xen_changeset VARCHAR(255) NULL,
  xen_hvbits VARCHAR(255) NULL,
  xen_dom0_kernel text NULL,
  xen_base_os_description text NULL,
  xen_guest_description text NULL,
  xen_guest_flags VARCHAR(255) NULL,
  xen_version VARCHAR(255) NULL,
  xen_guest_test VARCHAR(255) NULL,
  xen_guest_start VARCHAR(255) NULL,
  kvm_kernel text NULL,
  kvm_base_os_description text NULL,
  kvm_guest_description text NULL,
  kvm_module_version VARCHAR(255) NULL,
  kvm_userspace_version VARCHAR(255) NULL,
  kvm_guest_flags VARCHAR(255) NULL,
  kvm_guest_test VARCHAR(255) NULL,
  kvm_guest_start VARCHAR(255) NULL,
  simnow_svn_version VARCHAR(255) NULL,
  simnow_version VARCHAR(255) NULL,
  simnow_svn_repository VARCHAR(255) NULL,
  simnow_device_interface_version VARCHAR(255) NULL,
  simnow_bsd_file VARCHAR(255) NULL,
  simnow_image_file VARCHAR(255) NULL,
  INDEX reportsection_idx_report_id (report_id),
  PRIMARY KEY (id)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4;

DROP TABLE IF EXISTS scenario;

--
-- Table: scenario
--
CREATE TABLE scenario (
  id integer(11) NOT NULL auto_increment,
  type VARCHAR(255) NOT NULL DEFAULT '',
  options text NULL,
  name VARCHAR(255) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS suite;

--
-- Table: suite
--
CREATE TABLE suite (
  id integer(11) NOT NULL auto_increment,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(255) NOT NULL,
  description text NOT NULL,
  INDEX suite_idx_name (name),
  PRIMARY KEY (id)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4;

DROP TABLE IF EXISTS testplan_instance;

--
-- Table: testplan_instance
--
CREATE TABLE testplan_instance (
  id integer(11) NOT NULL auto_increment,
  path VARCHAR(255) NULL DEFAULT '',
  name VARCHAR(255) NULL DEFAULT '',
  evaluated_testplan mediumtext NULL DEFAULT '',
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4;

DROP TABLE IF EXISTS topic;

--
-- Table: topic
--
CREATE TABLE topic (
  name VARCHAR(255) NOT NULL,
  description text NOT NULL DEFAULT '',
  PRIMARY KEY (name)
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS contact;

--
-- Table: contact
--
CREATE TABLE contact (
  id integer(11) NOT NULL auto_increment,
  owner_id integer(11) NOT NULL,
  address VARCHAR(255) NOT NULL,
  protocol VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  INDEX contact_idx_owner_id (owner_id),
  PRIMARY KEY (id),
  CONSTRAINT contact_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS host_feature;

--
-- Table: host_feature
--
CREATE TABLE host_feature (
  id integer(11) NOT NULL auto_increment,
  host_id integer NOT NULL,
  entry VARCHAR(255) NOT NULL,
  value VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  INDEX host_feature_idx_host_id (host_id),
  PRIMARY KEY (id),
  CONSTRAINT host_feature_fk_host_id FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS notification;

--
-- Table: notification
--
CREATE TABLE notification (
  id integer(11) NOT NULL auto_increment,
  owner_id integer(11) NULL,
  persist integer(1) NULL,
  event VARCHAR(255) NOT NULL,
  filter text NOT NULL,
  comment VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  INDEX notification_idx_owner_id (owner_id),
  PRIMARY KEY (id),
  CONSTRAINT notification_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS pre_precondition;

--
-- Table: pre_precondition
--
CREATE TABLE pre_precondition (
  parent_precondition_id integer(11) NOT NULL,
  child_precondition_id integer(11) NOT NULL,
  succession integer(10) NOT NULL,
  INDEX pre_precondition_idx_child_precondition_id (child_precondition_id),
  INDEX pre_precondition_idx_parent_precondition_id (parent_precondition_id),
  PRIMARY KEY (parent_precondition_id, child_precondition_id),
  CONSTRAINT pre_precondition_fk_child_precondition_id FOREIGN KEY (child_precondition_id) REFERENCES precondition (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT pre_precondition_fk_parent_precondition_id FOREIGN KEY (parent_precondition_id) REFERENCES precondition (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS report;

--
-- Table: report
--
CREATE TABLE report (
  id integer(11) NOT NULL auto_increment,
  suite_id integer(11) NULL,
  suite_version VARCHAR(255) NULL,
  reportername VARCHAR(255) NULL DEFAULT '',
  peeraddr VARCHAR(255) NULL DEFAULT '',
  peerport VARCHAR(255) NULL DEFAULT '',
  peerhost VARCHAR(255) NULL DEFAULT '',
  successgrade VARCHAR(10) NULL DEFAULT '',
  reviewed_successgrade VARCHAR(10) NULL DEFAULT '',
  total integer(10) NULL,
  failed integer(10) NULL,
  parse_errors integer(10) NULL,
  passed integer(10) NULL,
  skipped integer(10) NULL,
  todo integer(10) NULL,
  todo_passed integer(10) NULL,
  success_ratio VARCHAR(20) NULL,
  starttime_test_program datetime NULL,
  endtime_test_program datetime NULL,
  machine_name VARCHAR(255) NULL DEFAULT '',
  machine_description text NULL DEFAULT '',
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  INDEX report_idx_suite_id (suite_id),
  INDEX report_idx_machine_name (machine_name),
  INDEX report_idx_created_at (created_at),
  PRIMARY KEY (id),
  CONSTRAINT report_fk_suite_id FOREIGN KEY (suite_id) REFERENCES suite (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS chart_tag_relations;

--
-- Table: chart_tag_relations
--
CREATE TABLE chart_tag_relations (
  chart_id integer(11) unsigned NOT NULL,
  chart_tag_id SMALLINT(6) unsigned NOT NULL,
  created_at TIMESTAMP NOT NULL,
  INDEX chart_tag_relations_idx_chart_id (chart_id),
  INDEX chart_tag_relations_idx_chart_tag_id (chart_tag_id),
  PRIMARY KEY (chart_id, chart_tag_id),
  CONSTRAINT chart_tag_relations_fk_chart_id FOREIGN KEY (chart_id) REFERENCES charts (chart_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chart_tag_relations_fk_chart_tag_id FOREIGN KEY (chart_tag_id) REFERENCES chart_tags (chart_tag_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS denied_host;

--
-- Table: denied_host
--
CREATE TABLE denied_host (
  id integer(11) NOT NULL auto_increment,
  queue_id integer(11) NOT NULL,
  host_id integer(11) NOT NULL,
  INDEX denied_host_idx_host_id (host_id),
  INDEX denied_host_idx_queue_id (queue_id),
  PRIMARY KEY (id),
  CONSTRAINT denied_host_fk_host_id FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT denied_host_fk_queue_id FOREIGN KEY (queue_id) REFERENCES queue (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS queue_host;

--
-- Table: queue_host
--
CREATE TABLE queue_host (
  id integer(11) NOT NULL auto_increment,
  queue_id integer(11) NOT NULL,
  host_id integer(11) NOT NULL,
  INDEX queue_host_idx_host_id (host_id),
  INDEX queue_host_idx_queue_id (queue_id),
  PRIMARY KEY (id),
  CONSTRAINT queue_host_fk_host_id FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT queue_host_fk_queue_id FOREIGN KEY (queue_id) REFERENCES queue (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS reportfile;

--
-- Table: reportfile
--
CREATE TABLE reportfile (
  id integer(11) NOT NULL auto_increment,
  report_id integer(11) NOT NULL,
  filename VARCHAR(255) NULL DEFAULT '',
  contenttype VARCHAR(255) NULL DEFAULT '',
  filecontent LONGBLOB NOT NULL DEFAULT '',
  is_compressed integer NOT NULL DEFAULT 0,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  INDEX reportfile_idx_report_id (report_id),
  INDEX reportfile_idx_filename (filename),
  PRIMARY KEY (id),
  CONSTRAINT reportfile_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4;

DROP TABLE IF EXISTS reportgrouparbitrary;

--
-- Table: reportgrouparbitrary
--
CREATE TABLE reportgrouparbitrary (
  arbitrary_id VARCHAR(255) NOT NULL,
  report_id integer(11) NOT NULL,
  primaryreport integer(11) NULL,
  owner VARCHAR(255) NULL,
  INDEX reportgrouparbitrary_idx_report_id (report_id),
  PRIMARY KEY (arbitrary_id, report_id),
  CONSTRAINT reportgrouparbitrary_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS reportgrouptestrun;

--
-- Table: reportgrouptestrun
--
CREATE TABLE reportgrouptestrun (
  testrun_id integer(11) NOT NULL,
  report_id integer(11) NOT NULL,
  primaryreport integer(11) NULL,
  owner VARCHAR(255) NULL,
  INDEX reportgrouptestrun_idx_report_id (report_id),
  PRIMARY KEY (testrun_id, report_id),
  CONSTRAINT reportgrouptestrun_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS reporttopic;

--
-- Table: reporttopic
--
CREATE TABLE reporttopic (
  id integer(11) NOT NULL auto_increment,
  report_id integer(11) NOT NULL,
  name VARCHAR(255) NULL DEFAULT '',
  details text NOT NULL DEFAULT '',
  INDEX reporttopic_idx_report_id (report_id),
  PRIMARY KEY (id),
  CONSTRAINT reporttopic_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS tap;

--
-- Table: tap
--
CREATE TABLE tap (
  id integer(11) NOT NULL auto_increment,
  report_id integer(11) NOT NULL,
  tap LONGBLOB NOT NULL DEFAULT '',
  tap_is_archive integer(11) NULL,
  tapdom LONGBLOB NULL DEFAULT '',
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  INDEX tap_idx_report_id (report_id),
  PRIMARY KEY (id),
  CONSTRAINT tap_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE
) ENGINE=InnoDB ROW_FORMAT=COMPRESSED KEY_BLOCK_SIZE=4;

DROP TABLE IF EXISTS testrun;

--
-- Table: testrun
--
CREATE TABLE testrun (
  id integer(11) NOT NULL auto_increment,
  shortname VARCHAR(255) NOT NULL,
  notes text NULL,
  topic_name VARCHAR(255) NOT NULL,
  starttime_earliest TIMESTAMP NULL,
  starttime_testrun TIMESTAMP NULL,
  starttime_test_program TIMESTAMP NULL,
  endtime_test_program TIMESTAMP NULL,
  owner_id integer(11) NULL,
  testplan_id integer(11) NULL,
  wait_after_tests TINYINT(1) NULL DEFAULT 0,
  rerun_on_error TINYINT(1) NULL DEFAULT 0,
  created_at TIMESTAMP NULL,
  updated_at TIMESTAMP NULL,
  INDEX testrun_idx_owner_id (owner_id),
  INDEX testrun_idx_testplan_id (testplan_id),
  INDEX testrun_idx_created_at (created_at),
  PRIMARY KEY (id),
  CONSTRAINT testrun_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id),
  CONSTRAINT testrun_fk_testplan_id FOREIGN KEY (testplan_id) REFERENCES testplan_instance (id) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_versions;

--
-- Table: chart_versions
--
CREATE TABLE chart_versions (
  chart_version_id integer(11) unsigned NOT NULL auto_increment,
  chart_id integer(11) unsigned NOT NULL,
  chart_type_id TINYINT(4) unsigned NOT NULL,
  chart_axis_type_x_id TINYINT(4) unsigned NOT NULL,
  chart_axis_type_y_id TINYINT(4) unsigned NOT NULL,
  chart_version TINYINT(4) unsigned NOT NULL,
  chart_name VARCHAR(64) NOT NULL,
  order_by_x_axis TINYINT(4) unsigned NOT NULL,
  order_by_y_axis TINYINT(4) unsigned NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NULL,
  INDEX chart_versions_idx_chart_id (chart_id),
  INDEX chart_versions_idx_chart_axis_type_x_id (chart_axis_type_x_id),
  INDEX chart_versions_idx_chart_axis_type_y_id (chart_axis_type_y_id),
  INDEX chart_versions_idx_chart_type_id (chart_type_id),
  PRIMARY KEY (chart_version_id),
  UNIQUE ux_chart_versions_01 (chart_id, chart_version),
  CONSTRAINT chart_versions_fk_chart_id FOREIGN KEY (chart_id) REFERENCES charts (chart_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chart_versions_fk_chart_axis_type_x_id FOREIGN KEY (chart_axis_type_x_id) REFERENCES chart_axis_types (chart_axis_type_id),
  CONSTRAINT chart_versions_fk_chart_axis_type_y_id FOREIGN KEY (chart_axis_type_y_id) REFERENCES chart_axis_types (chart_axis_type_id),
  CONSTRAINT chart_versions_fk_chart_type_id FOREIGN KEY (chart_type_id) REFERENCES chart_types (chart_type_id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS message;

--
-- Table: message
--
CREATE TABLE message (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NULL,
  message text NULL,
  type VARCHAR(255) NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  INDEX message_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  CONSTRAINT message_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS reportcomment;

--
-- Table: reportcomment
--
CREATE TABLE reportcomment (
  id integer(11) NOT NULL auto_increment,
  report_id integer(11) NOT NULL,
  owner_id integer(11) NULL,
  succession integer(10) NULL,
  comment text NOT NULL DEFAULT '',
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  INDEX reportcomment_idx_owner_id (owner_id),
  INDEX reportcomment_idx_report_id (report_id),
  PRIMARY KEY (id),
  CONSTRAINT reportcomment_fk_owner_id FOREIGN KEY (owner_id) REFERENCES owner (id),
  CONSTRAINT reportcomment_fk_report_id FOREIGN KEY (report_id) REFERENCES report (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS state;

--
-- Table: state
--
CREATE TABLE state (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  state text NULL,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  INDEX state_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  UNIQUE unique_testrun_id (testrun_id),
  CONSTRAINT state_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS testrun_requested_feature;

--
-- Table: testrun_requested_feature
--
CREATE TABLE testrun_requested_feature (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  feature VARCHAR(255) NULL DEFAULT '',
  INDEX testrun_requested_feature_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  CONSTRAINT testrun_requested_feature_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_lines;

--
-- Table: chart_lines
--
CREATE TABLE chart_lines (
  chart_line_id integer(11) unsigned NOT NULL auto_increment,
  chart_version_id integer(11) unsigned NOT NULL,
  chart_line_name VARCHAR(128) NOT NULL,
  chart_axis_x_column_format VARCHAR(64) NOT NULL,
  chart_axis_y_column_format VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL,
  INDEX chart_lines_idx_chart_version_id (chart_version_id),
  PRIMARY KEY (chart_line_id),
  UNIQUE ux_chart_lines_01 (chart_version_id, chart_line_name),
  CONSTRAINT chart_lines_fk_chart_version_id FOREIGN KEY (chart_version_id) REFERENCES chart_versions (chart_version_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_markings;

--
-- Table: chart_markings
--
CREATE TABLE chart_markings (
  chart_marking_id integer(11) unsigned NOT NULL auto_increment,
  chart_version_id integer(11) unsigned NOT NULL,
  chart_marking_name VARCHAR(128) NOT NULL,
  chart_marking_color CHAR(6) NOT NULL,
  chart_marking_x_from text NULL,
  chart_marking_x_to text NULL,
  chart_marking_x_format VARCHAR(64) NULL,
  chart_marking_y_from text NULL,
  chart_marking_y_to text NULL,
  chart_marking_y_format VARCHAR(64) NULL,
  created_at TIMESTAMP NOT NULL,
  INDEX chart_markings_idx_chart_version_id (chart_version_id),
  PRIMARY KEY (chart_marking_id),
  CONSTRAINT chart_markings_fk_chart_version_id FOREIGN KEY (chart_version_id) REFERENCES chart_versions (chart_version_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS scenario_element;

--
-- Table: scenario_element
--
CREATE TABLE scenario_element (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  scenario_id integer(11) NOT NULL,
  is_fitted integer(1) NOT NULL DEFAULT 0,
  INDEX scenario_element_idx_scenario_id (scenario_id),
  INDEX scenario_element_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  CONSTRAINT scenario_element_fk_scenario_id FOREIGN KEY (scenario_id) REFERENCES scenario (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT scenario_element_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS testrun_precondition;

--
-- Table: testrun_precondition
--
CREATE TABLE testrun_precondition (
  testrun_id integer(11) NOT NULL,
  precondition_id integer(11) NOT NULL,
  succession integer(10) NULL,
  INDEX testrun_precondition_idx_precondition_id (precondition_id),
  INDEX testrun_precondition_idx_testrun_id (testrun_id),
  PRIMARY KEY (testrun_id, precondition_id),
  CONSTRAINT testrun_precondition_fk_precondition_id FOREIGN KEY (precondition_id) REFERENCES precondition (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT testrun_precondition_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS testrun_requested_host;

--
-- Table: testrun_requested_host
--
CREATE TABLE testrun_requested_host (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  host_id integer(11) NOT NULL,
  INDEX testrun_requested_host_idx_host_id (host_id),
  INDEX testrun_requested_host_idx_testrun_id (testrun_id),
  PRIMARY KEY (id),
  CONSTRAINT testrun_requested_host_fk_host_id FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT testrun_requested_host_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_line_additionals;

--
-- Table: chart_line_additionals
--
CREATE TABLE chart_line_additionals (
  chart_line_id integer(11) unsigned NOT NULL,
  chart_line_additional_column text NOT NULL,
  chart_line_additional_url text NULL,
  created_at TIMESTAMP NOT NULL,
  INDEX chart_line_additionals_idx_chart_line_id (chart_line_id),
  PRIMARY KEY (chart_line_id, chart_line_additional_column(767)),
  CONSTRAINT chart_line_additionals_fk_chart_line_id FOREIGN KEY (chart_line_id) REFERENCES chart_lines (chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB ROW_FORMAT=DYNAMIC;

DROP TABLE IF EXISTS chart_line_axis_elements;

--
-- Table: chart_line_axis_elements
--
CREATE TABLE chart_line_axis_elements (
  chart_line_axis_element_id integer(11) unsigned NOT NULL auto_increment,
  chart_line_id integer(11) unsigned NOT NULL,
  chart_line_axis CHAR(1) NOT NULL,
  chart_line_axis_element_number TINYINT(4) unsigned NOT NULL,
  INDEX chart_line_axis_elements_idx_chart_line_id (chart_line_id),
  PRIMARY KEY (chart_line_axis_element_id),
  UNIQUE ux_chart_line_axis_elements_01 (chart_line_id, chart_line_axis, chart_line_axis_element_number),
  CONSTRAINT chart_line_axis_elements_fk_chart_line_id FOREIGN KEY (chart_line_id) REFERENCES chart_lines (chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_line_restrictions;

--
-- Table: chart_line_restrictions
--
CREATE TABLE chart_line_restrictions (
  chart_line_restriction_id integer(11) unsigned NOT NULL auto_increment,
  chart_line_id integer(11) unsigned NOT NULL,
  chart_line_restriction_operator VARCHAR(8) NOT NULL,
  chart_line_restriction_column text NOT NULL,
  is_template_restriction TINYINT(3) unsigned NOT NULL,
  is_numeric_restriction TINYINT(3) unsigned NOT NULL,
  created_at TIMESTAMP NOT NULL,
  INDEX chart_line_restrictions_idx_chart_line_id (chart_line_id),
  PRIMARY KEY (chart_line_restriction_id),
  CONSTRAINT chart_line_restrictions_fk_chart_line_id FOREIGN KEY (chart_line_id) REFERENCES chart_lines (chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS testrun_scheduling;

--
-- Table: testrun_scheduling
--
CREATE TABLE testrun_scheduling (
  id integer(11) NOT NULL auto_increment,
  testrun_id integer(11) NOT NULL,
  queue_id integer(11) NULL DEFAULT 0,
  host_id integer(11) NULL,
  prioqueue_seq integer(11) NULL,
  status VARCHAR(191) NULL DEFAULT 'prepare',
  auto_rerun TINYINT NULL DEFAULT 0,
  created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at datetime NULL,
  INDEX testrun_scheduling_idx_host_id (host_id),
  INDEX testrun_scheduling_idx_queue_id (queue_id),
  INDEX testrun_scheduling_idx_testrun_id (testrun_id),
  INDEX testrun_scheduling_idx_created_at (created_at),
  INDEX testrun_scheduling_idx_status (status),
  PRIMARY KEY (id),
  CONSTRAINT testrun_scheduling_fk_host_id FOREIGN KEY (host_id) REFERENCES host (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT testrun_scheduling_fk_queue_id FOREIGN KEY (queue_id) REFERENCES queue (id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT testrun_scheduling_fk_testrun_id FOREIGN KEY (testrun_id) REFERENCES testrun (id) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_line_axis_columns;

--
-- Table: chart_line_axis_columns
--
CREATE TABLE chart_line_axis_columns (
  chart_line_axis_element_id integer(11) unsigned NOT NULL,
  chart_line_axis_column text NOT NULL,
  INDEX (chart_line_axis_element_id),
  PRIMARY KEY (chart_line_axis_element_id),
  CONSTRAINT chart_line_axis_columns_fk_chart_line_axis_element_id FOREIGN KEY (chart_line_axis_element_id) REFERENCES chart_line_axis_elements (chart_line_axis_element_id) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_line_axis_separators;

--
-- Table: chart_line_axis_separators
--
CREATE TABLE chart_line_axis_separators (
  chart_line_axis_element_id integer(11) unsigned NOT NULL,
  chart_line_axis_separator VARCHAR(128) NOT NULL,
  INDEX (chart_line_axis_element_id),
  PRIMARY KEY (chart_line_axis_element_id),
  CONSTRAINT chart_line_axis_separators_fk_chart_line_axis_element_id FOREIGN KEY (chart_line_axis_element_id) REFERENCES chart_line_axis_elements (chart_line_axis_element_id) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_line_restriction_values;

--
-- Table: chart_line_restriction_values
--
CREATE TABLE chart_line_restriction_values (
  chart_line_restriction_value_id integer(11) unsigned NOT NULL auto_increment,
  chart_line_restriction_id integer(11) unsigned NOT NULL,
  chart_line_restriction_value text NOT NULL,
  INDEX chart_line_restriction_values_idx_chart_line_restriction_id (chart_line_restriction_id),
  PRIMARY KEY (chart_line_restriction_value_id),
  CONSTRAINT chart_line_restriction_values_fk_chart_line_restriction_id FOREIGN KEY (chart_line_restriction_id) REFERENCES chart_line_restrictions (chart_line_restriction_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_tiny_url_lines;

--
-- Table: chart_tiny_url_lines
--
CREATE TABLE chart_tiny_url_lines (
  chart_tiny_url_line_id integer(12) unsigned NOT NULL auto_increment,
  chart_tiny_url_id integer(12) unsigned NOT NULL,
  chart_line_id integer(12) unsigned NOT NULL,
  INDEX chart_tiny_url_lines_idx_chart_line_id (chart_line_id),
  INDEX chart_tiny_url_lines_idx_chart_tiny_url_id (chart_tiny_url_id),
  PRIMARY KEY (chart_tiny_url_line_id),
  CONSTRAINT chart_tiny_url_lines_fk_chart_line_id FOREIGN KEY (chart_line_id) REFERENCES chart_lines (chart_line_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chart_tiny_url_lines_fk_chart_tiny_url_id FOREIGN KEY (chart_tiny_url_id) REFERENCES chart_tiny_urls (chart_tiny_url_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS chart_tiny_url_relations;

--
-- Table: chart_tiny_url_relations
--
CREATE TABLE chart_tiny_url_relations (
  chart_tiny_url_line_id integer(12) unsigned NOT NULL,
  bench_value_id integer(12) unsigned NOT NULL,
  INDEX chart_tiny_url_relations_idx_bench_value_id (bench_value_id),
  INDEX chart_tiny_url_relations_idx_chart_tiny_url_line_id (chart_tiny_url_line_id),
  PRIMARY KEY (chart_tiny_url_line_id, bench_value_id),
  CONSTRAINT chart_tiny_url_relations_fk_chart_tiny_url_line_id FOREIGN KEY (chart_tiny_url_line_id) REFERENCES chart_tiny_url_lines (chart_tiny_url_line_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

--
-- Table: resource
--

DROP TABLE IF EXISTS resource;

CREATE TABLE resource (
  id INTEGER PRIMARY KEY NOT NULL auto_increment,
  name VARCHAR(255) DEFAULT '',
  comment VARCHAR(255) DEFAULT '',
  active TINYINT NOT NULL DEFAULT 0,
  used_by_scheduling_id INT(11),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME,
  FOREIGN KEY (used_by_scheduling_id) REFERENCES testrun_scheduling(id) ON DELETE SET NULL ON UPDATE CASCADE
);

--
-- Table: testrun_requested_resource
--

DROP TABLE IF EXISTS testrun_requested_resource;

CREATE TABLE testrun_requested_resource (
  id INTEGER PRIMARY KEY NOT NULL auto_increment,
  testrun_id INT(11) NOT NULL,
  selected_resource_id INT(11),
  FOREIGN KEY (selected_resource_id) REFERENCES resource(id) ON DELETE SET NULL,
  FOREIGN KEY (testrun_id) REFERENCES testrun(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX testrun_requested_resource_idx_selected_resource_id ON testrun_requested_resource (selected_resource_id);
CREATE INDEX testrun_requested_resource_idx_testrun_id ON testrun_requested_resource (testrun_id);

--
-- Table: testrun_requested_resource_alternative
--

DROP TABLE IF EXISTS testrun_requested_resource_alternative;

CREATE TABLE testrun_requested_resource_alternative (
  id INTEGER PRIMARY KEY NOT NULL auto_increment,
  request_id INT(11) NOT NULL,
  resource_id INT(11) NOT NULL,
  FOREIGN KEY (request_id) REFERENCES testrun_requested_resource(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (resource_id) REFERENCES resource(id) ON DELETE CASCADE
);
CREATE INDEX testrun_requested_resource_alternative_idx_request_id ON testrun_requested_resource_alternative (request_id);
CREATE INDEX testrun_requested_resource_alternative_idx_resource_id ON testrun_requested_resource_alternative (resource_id);

--
-- Table: testrun_dependency;
--

DROP TABLE IF EXISTS testrun_dependency;

CREATE TABLE testrun_dependency (
  dependee_testrun_id INT(11) NOT NULL,
  depender_testrun_id INT(11) NOT NULL,
  PRIMARY KEY (dependee_testrun_id, depender_testrun_id),
  FOREIGN KEY (dependee_testrun_id) REFERENCES testrun(id) ON DELETE CASCADE,
  FOREIGN KEY (depender_testrun_id) REFERENCES testrun(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX testrun_dependency_idx_dependee_testrun_id ON testrun_dependency (dependee_testrun_id);
CREATE INDEX testrun_dependency_idx_depender_testrun_id ON testrun_dependency (depender_testrun_id);

SET foreign_key_checks=1;
