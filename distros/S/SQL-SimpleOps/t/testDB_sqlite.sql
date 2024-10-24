-- -----------------------------------------------------
-- Tables
-- -----------------------------------------------------

CREATE TABLE standard_notnull (
	i_integer integer not null,
	s_text text not null,
	s_blob blob not null,
	f_real real not null,
	i_numeric numeric not null
	);

CREATE TABLE standard_null (
	i_integer integer null,
	s_text text null,
	s_blob blob null,
	f_real real null,
	i_numeric numeric null
	);

CREATE TABLE standard_single (
	i_id integer
	);

CREATE TABLE autoincrement_1 (
	i_id integer primary key autoincrement,
	i_no_1 integer signed not null,
	i_no_2 integer unsigned not null
	);

CREATE TABLE standard_indexed (
	i_fld_1 integer,
	i_fld_2 integer
	);

CREATE TABLE master (
	i_m_id integer primary key autoincrement,
	s_m_code text,
	s_m_name text,
	s_m_desc text
	);

CREATE TABLE slave (
	i_s_id integer primary key autoincrement,
	s_m_code text,
	s_s_code text,
	s_s_name text,
	s_s_desc text
	);

-- -----------------------------------------------------
-- ENDED
-- -----------------------------------------------------
