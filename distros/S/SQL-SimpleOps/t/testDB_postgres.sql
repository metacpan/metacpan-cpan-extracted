-- -----------------------------------------------------
-- Cleanup
-- -----------------------------------------------------

DROP TABLE IF EXISTS %SCHEMA%.standard_notnull ;
DROP TABLE IF EXISTS %SCHEMA%.standard_null ;
DROP TABLE IF EXISTS %SCHEMA%.standard_single ;
DROP TABLE IF EXISTS %SCHEMA%.autoincrement_1 ;
DROP TABLE IF EXISTS %SCHEMA%.standard_indexed ;
DROP TABLE IF EXISTS %SCHEMA%.master ;
DROP TABLE IF EXISTS %SCHEMA%.slave ;

DROP SCHEMA IF EXISTS %SCHEMA% CASCADE ;
DROP DATABASE IF EXISTS %DSNAME% ;

DROP ROLE IF EXISTS user_read;
DROP ROLE IF EXISTS user_update;

-- -----------------------------------------------------
-- Schema
-- -----------------------------------------------------

CREATE DATABASE %DSNAME% ENCODING 'UTF8';

CREATE SCHEMA IF NOT EXISTS %SCHEMA% ;

-- -----------------------------------------------------
-- Tables
-- -----------------------------------------------------

CREATE TABLE IF NOT EXISTS %SCHEMA%.standard_notnull (
	i_smallint smallint not null,
	i_integer integer not null,
	i_bigint bigint not null,
	i_decimal decimal not null,
	i_numeric numeric not null,
	f_real real not null,
	f_double_precision double precision not null,
	f_money money not null,
	s_character_varying character varying(255) not null,
	s_varchar varchar(255) not null,
	s_char char(255) not null,
	s_text text not null,
	s_bytea bytea not null,
	t_timestamp timestamp not null,
	t_date date not null,
	t_time time not null,
	t_interval interval not null,
	b_boolean boolean not null
	);

CREATE TABLE IF NOT EXISTS %SCHEMA%.standard_null (
	i_smallint smallint null,
	i_integer integer null,
	i_bigint bigint null,
	i_decimal decimal null,
	i_numeric numeric null,
	f_real real null,
	f_double_precision double precision null,
	f_money money null,
	s_character_varying character varying(255) null,
	s_varchar varchar(255) null,
	s_char char(255) null,
	s_text text null,
	s_bytea bytea not null,
	t_timestamp timestamp null,
	t_date date null,
	t_time time null,
	t_interval interval null,
	b_boolean boolean null
	);

CREATE TABLE IF NOT EXISTS %SCHEMA%.standard_single (
	i_id integer
	);

CREATE TABLE IF NOT EXISTS %SCHEMA%.autoincrement_1 (
	i_id serial unique,
	i_no_1 bigint not null,
	i_no_2 bigint not null
	);

CREATE TABLE IF NOT EXISTS %SCHEMA%.standard_indexed (
	i_fld_1 integer,
	i_fld_2 integer
	);

CREATE TABLE IF NOT EXISTS %SCHEMA%.master (
	i_m_id smallserial unique,
	s_m_code varchar(32),
	s_m_name varchar(255),
	s_m_desc varchar(255)
	);

CREATE TABLE IF NOT EXISTS %SCHEMA%.slave (
	i_s_id smallserial unique,
	s_m_code varchar(32),
	s_s_code varchar(32),
	s_s_name varchar(255),
	s_s_desc varchar(255)
	);

-- -----------------------------------------------------
-- Users
-- -----------------------------------------------------

CREATE ROLE user_read LOGIN PASSWORD 'password_read';
CREATE ROLE user_update LOGIN PASSWORD 'password_update';

GRANT SELECT ON ALL TABLES IN SCHEMA %SCHEMA% TO user_read;
GRANT ALL ON ALL TABLES IN SCHEMA %SCHEMA% TO user_update;

GRANT SELECT ON DATABASE %DSNAME% TO user_read;
GRANT ALL ON DATABASE %DSNAME% TO user_update;

GRANT pg_read_all_data TO user_read;
GRANT pg_write_all_data TO user_update;

-- -----------------------------------------------------
-- ENDED
-- -----------------------------------------------------
