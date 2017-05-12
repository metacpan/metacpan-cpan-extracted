-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed Jan 26 15:13:32 2011
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `host`;

--
-- Table: `host`
--
CREATE TABLE `host` (
  `id` integer(11) NOT NULL auto_increment,
  `name` VARCHAR(255) DEFAULT '',
  `comment` VARCHAR(255) DEFAULT '',
  `free` TINYINT DEFAULT 0,
  `active` TINYINT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `precondition`;

--
-- Table: `precondition`
--
CREATE TABLE `precondition` (
  `id` integer(11) NOT NULL auto_increment,
  `shortname` VARCHAR(255) NOT NULL DEFAULT '',
  `precondition` text,
  `timeout` integer(10),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `preconditiontype`;

--
-- Table: `preconditiontype`
--
CREATE TABLE `preconditiontype` (
  `name` VARCHAR(20) NOT NULL,
  `description` text NOT NULL DEFAULT '',
  PRIMARY KEY (`name`)
);

DROP TABLE IF EXISTS `queue`;

--
-- Table: `queue`
--
CREATE TABLE `queue` (
  `id` integer(11) NOT NULL auto_increment,
  `name` VARCHAR(255) DEFAULT '',
  `priority` integer(10) NOT NULL DEFAULT 0,
  `runcount` integer(10) NOT NULL DEFAULT 0,
  `active` integer(1) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  PRIMARY KEY (`id`),
  UNIQUE `unique_queue_name` (`name`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `scenario`;

--
-- Table: `scenario`
--
CREATE TABLE `scenario` (
  `id` integer(11) NOT NULL auto_increment,
  `type` VARCHAR(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `topic`;

--
-- Table: `topic`
--
CREATE TABLE `topic` (
  `name` VARCHAR(255) NOT NULL,
  `description` text NOT NULL DEFAULT '',
  PRIMARY KEY (`name`)
);

DROP TABLE IF EXISTS `user`;

--
-- Table: `user`
--
CREATE TABLE `user` (
  `id` integer(11) NOT NULL auto_increment,
  `name` VARCHAR(255) NOT NULL,
  `login` VARCHAR(255) NOT NULL,
  `password` VARCHAR(255),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `host_feature`;

--
-- Table: `host_feature`
--
CREATE TABLE `host_feature` (
  `id` integer(11) NOT NULL auto_increment,
  `host_id` integer NOT NULL,
  `entry` VARCHAR(255) NOT NULL,
  `value` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  INDEX `host_feature_idx_host_id` (`host_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `host_feature_fk_host_id` FOREIGN KEY (`host_id`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `pre_precondition`;

--
-- Table: `pre_precondition`
--
CREATE TABLE `pre_precondition` (
  `parent_precondition_id` integer(11) NOT NULL,
  `child_precondition_id` integer(11) NOT NULL,
  `succession` integer(10) NOT NULL,
  INDEX `pre_precondition_idx_child_precondition_id` (`child_precondition_id`),
  INDEX `pre_precondition_idx_parent_precondition_id` (`parent_precondition_id`),
  PRIMARY KEY (`parent_precondition_id`, `child_precondition_id`),
  CONSTRAINT `pre_precondition_fk_child_precondition_id` FOREIGN KEY (`child_precondition_id`) REFERENCES `precondition` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `pre_precondition_fk_parent_precondition_id` FOREIGN KEY (`parent_precondition_id`) REFERENCES `precondition` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `testrun`;

--
-- Table: `testrun`
--
CREATE TABLE `testrun` (
  `id` integer(11) NOT NULL auto_increment,
  `shortname` VARCHAR(255) DEFAULT '',
  `notes` text DEFAULT '',
  `topic_name` VARCHAR(255) NOT NULL DEFAULT '',
  `starttime_earliest` datetime,
  `starttime_testrun` datetime,
  `starttime_test_program` datetime,
  `endtime_test_program` datetime,
  `owner_user_id` integer(11),
  `wait_after_tests` integer(1) DEFAULT 0,
  `rerun_on_error` integer(11) DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  INDEX `testrun_idx_owner_user_id` (`owner_user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `testrun_fk_owner_user_id` FOREIGN KEY (`owner_user_id`) REFERENCES `user` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `message`;

--
-- Table: `message`
--
CREATE TABLE `message` (
  `id` integer(11) NOT NULL auto_increment,
  `testrun_id` integer(11) NOT NULL,
  `message` text,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  INDEX `message_idx_testrun_id` (`testrun_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `message_fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `queue_host`;

--
-- Table: `queue_host`
--
CREATE TABLE `queue_host` (
  `id` integer(11) NOT NULL auto_increment,
  `queue_id` integer(11) NOT NULL,
  `host_id` integer,
  INDEX `queue_host_idx_host_id` (`host_id`),
  INDEX `queue_host_idx_queue_id` (`queue_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `queue_host_fk_host_id` FOREIGN KEY (`host_id`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `queue_host_fk_queue_id` FOREIGN KEY (`queue_id`) REFERENCES `queue` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `state`;

--
-- Table: `state`
--
CREATE TABLE `state` (
  `id` integer(11) NOT NULL auto_increment,
  `testrun_id` integer(11) NOT NULL,
  `state` text,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  INDEX `state_idx_testrun_id` (`testrun_id`),
  PRIMARY KEY (`id`),
  UNIQUE `unique_testrun_id` (`testrun_id`),
  CONSTRAINT `state_fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `testrun_requested_feature`;

--
-- Table: `testrun_requested_feature`
--
CREATE TABLE `testrun_requested_feature` (
  `id` integer(11) NOT NULL auto_increment,
  `testrun_id` integer(11) NOT NULL,
  `feature` VARCHAR(255) DEFAULT '',
  INDEX `testrun_requested_feature_idx_testrun_id` (`testrun_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `testrun_requested_feature_fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `scenario_element`;

--
-- Table: `scenario_element`
--
CREATE TABLE `scenario_element` (
  `id` integer(11) NOT NULL auto_increment,
  `testrun_id` integer(11) NOT NULL,
  `scenario_id` integer(11) NOT NULL,
  `is_fitted` integer(1) NOT NULL DEFAULT 0,
  INDEX `scenario_element_idx_scenario_id` (`scenario_id`),
  INDEX `scenario_element_idx_testrun_id` (`testrun_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `scenario_element_fk_scenario_id` FOREIGN KEY (`scenario_id`) REFERENCES `scenario` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `scenario_element_fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `testrun_precondition`;

--
-- Table: `testrun_precondition`
--
CREATE TABLE `testrun_precondition` (
  `testrun_id` integer(11) NOT NULL,
  `precondition_id` integer(11) NOT NULL,
  `succession` integer(10),
  INDEX `testrun_precondition_idx_precondition_id` (`precondition_id`),
  INDEX `testrun_precondition_idx_testrun_id` (`testrun_id`),
  PRIMARY KEY (`testrun_id`, `precondition_id`),
  CONSTRAINT `testrun_precondition_fk_precondition_id` FOREIGN KEY (`precondition_id`) REFERENCES `precondition` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `testrun_precondition_fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `testrun_requested_host`;

--
-- Table: `testrun_requested_host`
--
CREATE TABLE `testrun_requested_host` (
  `id` integer(11) NOT NULL auto_increment,
  `testrun_id` integer(11) NOT NULL,
  `host_id` integer,
  INDEX `testrun_requested_host_idx_host_id` (`host_id`),
  INDEX `testrun_requested_host_idx_testrun_id` (`testrun_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `testrun_requested_host_fk_host_id` FOREIGN KEY (`host_id`) REFERENCES `host` (`id`),
  CONSTRAINT `testrun_requested_host_fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `testrun_scheduling`;

--
-- Table: `testrun_scheduling`
--
CREATE TABLE `testrun_scheduling` (
  `id` integer(11) NOT NULL auto_increment,
  `testrun_id` integer(11) NOT NULL,
  `queue_id` integer(11) DEFAULT 0,
  `host_id` integer(11),
  `prioqueue_seq` integer(11),
  `status` VARCHAR(255) DEFAULT 'prepare',
  `auto_rerun` TINYINT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  INDEX `testrun_scheduling_idx_host_id` (`host_id`),
  INDEX `testrun_scheduling_idx_queue_id` (`queue_id`),
  INDEX `testrun_scheduling_idx_testrun_id` (`testrun_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `testrun_scheduling_fk_host_id` FOREIGN KEY (`host_id`) REFERENCES `host` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `testrun_scheduling_fk_queue_id` FOREIGN KEY (`queue_id`) REFERENCES `queue` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `testrun_scheduling_fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

