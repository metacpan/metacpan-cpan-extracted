-- Convert schema 'lib/auto/Tapper/Schema/Tapper-Schema-ReportsDB-3.000005-MySQL.sql' to 'Tapper::Schema::ReportsDB v3.000006':;

BEGIN;

SET foreign_key_checks=0;

CREATE TABLE `contact` (
  `id` integer(11) NOT NULL auto_increment,
  `user_id` integer(11) NOT NULL,
  `address` VARCHAR(255) NOT NULL,
  `protocol` VARCHAR(255) NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  INDEX `contact_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `contact_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `notification` (
  `id` integer(11) NOT NULL auto_increment,
  `user_id` integer(11),
  `persist` integer(1),
  `event` VARCHAR(255) NOT NULL,
  `condition` text NOT NULL,
  `comment` VARCHAR(255),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  INDEX `notification_idx_user_id` (`user_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `notification_fk_user_id` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `notification_event` (
  `id` integer(11) NOT NULL auto_increment,
  `message` VARCHAR(255),
  `type` VARCHAR(255),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime,
  PRIMARY KEY (`id`)
);

SET foreign_key_checks=1;


COMMIT;

