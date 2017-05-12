-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Thu Apr  2 15:45:07 2015
-- 
SET foreign_key_checks=0--
-- Table: `test`
--
CREATE TABLE `test` (
  `id` integer(11) NULL DEFAULT NULL,
  `name` varchar(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARACTER SET utf8
SET foreign_key_checks=1