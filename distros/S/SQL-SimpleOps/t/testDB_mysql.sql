-- -----------------------------------------------------
-- Cleanup
-- -----------------------------------------------------

DROP TABLE IF EXISTS `%DSNAME%`.`standard_notnull` ;
DROP TABLE IF EXISTS `%DSNAME%`.`standard_null` ;
DROP TABLE IF EXISTS `%DSNAME%`.`standard_single` ;
DROP TABLE IF EXISTS `%DSNAME%`.`autoincrement_1` ;
DROP TABLE IF EXISTS `%DSNAME%`.`standard_indexed` ;
DROP TABLE IF EXISTS `%DSNAME%`.`master` ;
DROP TABLE IF EXISTS `%DSNAME%`.`slave` ;

DROP SCHEMA IF EXISTS `%DSNAME%` ;

DROP USER IF EXISTS 'user_read'@'%HOSTNAME%';
DROP USER IF EXISTS 'user_update'@'%HOSTNAME%';

-- -----------------------------------------------------
-- Schema
-- -----------------------------------------------------

CREATE SCHEMA IF NOT EXISTS `%DSNAME%` DEFAULT CHARACTER SET utf8 ;

USE `%DSNAME%` ;

-- -----------------------------------------------------
-- Tables
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS `%DSNAME%`.`standard_notnull` (
	b_binary binary not null,
	b_varbinary varbinary(1) not null,
	b_bool bool not null,
	b_boolean boolean not null,
	f_float float not null,
	f_double double not null,
	f_double_precision double precision not null,
	f_decimal decimal not null,
	f_dec dec not null,
	i_tinyint tinyint not null,
	i_smallint smallint not null,
	i_mediumint mediumint not null,
	i_int int not null,
	i_integer integer not null,
	i_bigint bigint not null,
	s_varchar varchar(4096) not null,
	s_tinyblob tinyblob not null,
	s_tinytext tinytext not null,
	s_text text not null,
	s_blob blob not null,
	s_mediumtext mediumtext not null,
	s_mediumblob mediumblob not null,
	s_longtext longtext not null,
	s_longblob longblob not null,
	t_date date not null,
	t_datetime datetime not null,
	t_timestamp timestamp not null,
	t_time time not null,
	t_year year not null
	) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `%DSNAME%`.`standard_null` (
	b_binary binary null,
	b_varbinary varbinary(1) null,
	b_bool bool null,
	b_boolean boolean null,
	f_float float null,
	f_double double null,
	f_double_precision double precision null,
	f_decimal decimal null,
	f_dec dec null,
	i_tinyint tinyint null,
	i_smallint smallint null,
	i_mediumint mediumint null,
	i_int int null,
	i_integer integer null,
	i_bigint bigint null,
	s_varchar varchar(4096) null,
	s_tinyblob tinyblob null,
	s_tinytext tinytext null,
	s_text text null,
	s_blob blob null,
	s_mediumtext mediumtext null,
	s_mediumblob mediumblob null,
	s_longtext longtext null,
	s_longblob longblob null,
	t_date date null,
	t_datetime datetime null,
	t_timestamp timestamp null,
	t_time time null,
	t_year year null
	) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `%DSNAME%`.`standard_single` (
	i_id int
	) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `%DSNAME%`.`autoincrement_1` (
	i_id int auto_increment unique,
	i_no_1 bigint signed not null,
	i_no_2 bigint unsigned not null
	) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `%DSNAME%`.`standard_indexed` (
	i_fld_1 int,
	i_fld_2 int
	) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `%DSNAME%`.`master` (
	i_m_id int auto_increment unique,
	s_m_code varchar(32),
	s_m_name varchar(255),
	s_m_desc varchar(255)
	) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS `%DSNAME%`.`slave` (
	i_s_id int auto_increment unique,
	s_m_code varchar(32),
	s_s_code varchar(32),
	s_s_name varchar(255),
	s_s_desc varchar(255)
	) ENGINE = InnoDB;

-- -----------------------------------------------------
-- Users
-- -----------------------------------------------------

CREATE USER 'user_read'@'%HOSTNAME%' IDENTIFIED BY 'password_read';
CREATE USER 'user_update'@'%HOSTNAME%' IDENTIFIED BY 'password_update';

GRANT SELECT ON `%DSNAME%`.* TO 'user_read'@'%HOSTNAME%';
GRANT SELECT,INSERT,UPDATE,DELETE ON `%DSNAME%`.* TO 'user_update'@'%HOSTNAME%';

-- -----------------------------------------------------
-- ENDED
-- -----------------------------------------------------
