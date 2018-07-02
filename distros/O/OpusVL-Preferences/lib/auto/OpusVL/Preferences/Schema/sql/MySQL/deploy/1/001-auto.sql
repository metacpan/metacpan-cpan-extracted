-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Wed May 16 10:10:58 2018
-- 
;
SET foreign_key_checks=0;
--
-- Table: `prf_owner_type`
--
CREATE TABLE `prf_owner_type` (
  `prf_owner_type_id` integer NOT NULL auto_increment,
  `owner_table` varchar(255) NOT NULL,
  `owner_resultset` varchar(255) NOT NULL,
  PRIMARY KEY (`prf_owner_type_id`),
  UNIQUE `prf_owner_type__resultset` (`owner_resultset`),
  UNIQUE `prf_owner_type__table` (`owner_table`)
) ENGINE=InnoDB;
--
-- Table: `prf_defaults`
--
CREATE TABLE `prf_defaults` (
  `prf_owner_type_id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  `default_value` varchar(255) NOT NULL,
  `data_type` varchar(255) NULL,
  `comment` varchar(255) NULL,
  `required` enum('0','1') NULL DEFAULT '0',
  `active` enum('0','1') NULL DEFAULT '1',
  `hidden` enum('0','1') NULL,
  `gdpr_erasable` enum('0','1') NULL,
  `audit` enum('0','1') NULL,
  `display_on_search` enum('0','1') NULL,
  `searchable` enum('0','1') NOT NULL DEFAULT '1',
  `unique_field` enum('0','1') NULL,
  `ajax_validate` enum('0','1') NULL,
  `display_order` integer NOT NULL DEFAULT 1,
  `confirmation_required` enum('0','1') NULL,
  `encrypted` enum('0','1') NULL,
  `display_mask` varchar(255) NOT NULL DEFAULT '(.*)',
  `mask_char` varchar(255) NOT NULL DEFAULT '*',
  INDEX `prf_defaults_idx_prf_owner_type_id` (`prf_owner_type_id`),
  PRIMARY KEY (`prf_owner_type_id`, `name`),
  CONSTRAINT `prf_defaults_fk_prf_owner_type_id` FOREIGN KEY (`prf_owner_type_id`) REFERENCES `prf_owner_type` (`prf_owner_type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `prf_owners`
--
CREATE TABLE `prf_owners` (
  `prf_owner_id` integer NOT NULL,
  `prf_owner_type_id` integer NOT NULL,
  INDEX `prf_owners_idx_prf_owner_type_id` (`prf_owner_type_id`),
  PRIMARY KEY (`prf_owner_id`, `prf_owner_type_id`),
  CONSTRAINT `prf_owners_fk_prf_owner_type_id` FOREIGN KEY (`prf_owner_type_id`) REFERENCES `prf_owner_type` (`prf_owner_type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `prf_default_values`
--
CREATE TABLE `prf_default_values` (
  `id` integer NOT NULL auto_increment,
  `value` text NULL,
  `prf_owner_type_id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  `display_order` integer NOT NULL DEFAULT 1,
  INDEX `prf_default_values_idx_prf_owner_type_id_name` (`prf_owner_type_id`, `name`),
  PRIMARY KEY (`id`),
  CONSTRAINT `prf_default_values_fk_prf_owner_type_id_name` FOREIGN KEY (`prf_owner_type_id`, `name`) REFERENCES `prf_defaults` (`prf_owner_type_id`, `name`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `prf_preferences`
--
CREATE TABLE `prf_preferences` (
  `prf_preference_id` integer NOT NULL auto_increment,
  `prf_owner_id` integer NOT NULL,
  `prf_owner_type_id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  `value` varchar(255) NULL,
  INDEX `prf_preferences_idx_prf_owner_id_prf_owner_type_id` (`prf_owner_id`, `prf_owner_type_id`),
  PRIMARY KEY (`prf_preference_id`),
  UNIQUE `prf_preferences_prf_preference_id_prf_owner_type_id_name` (`prf_preference_id`, `prf_owner_type_id`, `name`),
  CONSTRAINT `prf_preferences_fk_prf_owner_id_prf_owner_type_id` FOREIGN KEY (`prf_owner_id`, `prf_owner_type_id`) REFERENCES `prf_owners` (`prf_owner_id`, `prf_owner_type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
--
-- Table: `prf_unique_vals`
--
CREATE TABLE `prf_unique_vals` (
  `id` integer NOT NULL auto_increment,
  `value_id` integer NOT NULL,
  `value` text NULL,
  `prf_owner_type_id` integer NOT NULL,
  `name` varchar(255) NOT NULL,
  INDEX `prf_unique_vals_idx_prf_owner_type_id_name` (`prf_owner_type_id`, `name`),
  INDEX `prf_unique_vals_idx_value_id_prf_owner_type_id_name` (`value_id`, `prf_owner_type_id`, `name`),
  PRIMARY KEY (`id`),
  UNIQUE `prf_unique_vals_value_id_prf_owner_type_id_name` (`value_id`, `prf_owner_type_id`, `name`),
  UNIQUE `prf_unique_vals_value_prf_owner_type_id_name` (`value`, `prf_owner_type_id`, `name`),
  CONSTRAINT `prf_unique_vals_fk_prf_owner_type_id_name` FOREIGN KEY (`prf_owner_type_id`, `name`) REFERENCES `prf_defaults` (`prf_owner_type_id`, `name`),
  CONSTRAINT `prf_unique_vals_fk_value_id_prf_owner_type_id_name` FOREIGN KEY (`value_id`, `prf_owner_type_id`, `name`) REFERENCES `prf_preferences` (`prf_preference_id`, `prf_owner_type_id`, `name`) ON DELETE CASCADE
) ENGINE=InnoDB;
SET foreign_key_checks=1;
