-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Mon Jun 30 12:35:11 2008
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `pre_precondition`;
--
-- Table: `pre_precondition`
--
CREATE TABLE `pre_precondition` (
  `parent_precondition_id` integer(11) NOT NULL,
  `child_precondition_id` integer(11) NOT NULL,
  `succession` integer(10) NOT NULL,
  INDEX (`child_precondition_id`),
  INDEX (`parent_precondition_id`),
  PRIMARY KEY (`parent_precondition_id`, `child_precondition_id`),
  CONSTRAINT `fk_child_precondition_id` FOREIGN KEY (`child_precondition_id`) REFERENCES `precondition` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_parent_precondition_id` FOREIGN KEY (`parent_precondition_id`) REFERENCES `precondition` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
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

DROP TABLE IF EXISTS `testrun`;
--
-- Table: `testrun`
--
CREATE TABLE `testrun` (
  `id` integer(11) NOT NULL auto_increment,
  `shortname` VARCHAR(255) DEFAULT '',
  `notes` text DEFAULT '',
  `topic_name` VARCHAR(20) NOT NULL DEFAULT '',
  `starttime_earliest` datetime,
  `starttime_testrun` datetime,
  `starttime_test_program` datetime,
  `endtime_test_program` datetime,
  `hardwaredb_systems_id` integer(11),
  `owner_user_id` integer(11),
  `test_program` VARCHAR(255) NOT NULL DEFAULT '',
  `timeout_after_testprogram` integer(10),
  `wait_after_tests` integer(1) DEFAULT '0',
  `created_at` datetime,
  `updated_at` datetime,
  INDEX (`owner_user_id`),
  INDEX (`topic_name`),
  PRIMARY KEY (`id`),
  CONSTRAINT `fk_owner_user_id` FOREIGN KEY (`owner_user_id`) REFERENCES `user` (`id`),
  CONSTRAINT `fk_topic_name` FOREIGN KEY (`topic_name`) REFERENCES `topic` (`name`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `testrun_precondition`;
--
-- Table: `testrun_precondition`
--
CREATE TABLE `testrun_precondition` (
  `testrun_id` integer(11) NOT NULL,
  `precondition_id` integer(11) NOT NULL,
  `succession` integer(10),
  INDEX (`precondition_id`),
  INDEX (`testrun_id`),
  PRIMARY KEY (`testrun_id`, `precondition_id`),
  CONSTRAINT `fk_precondition_id` FOREIGN KEY (`precondition_id`) REFERENCES `precondition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_testrun_id` FOREIGN KEY (`testrun_id`) REFERENCES `testrun` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `topic`;
--
-- Table: `topic`
--
CREATE TABLE `topic` (
  `name` VARCHAR(20) NOT NULL,
  `description` text NOT NULL DEFAULT '',
  PRIMARY KEY (`name`)
) ENGINE=InnoDB;

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

SET foreign_key_checks=1;

