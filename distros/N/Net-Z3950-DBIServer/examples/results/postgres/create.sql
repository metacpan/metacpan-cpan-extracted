\connect template1
DROP DATABASE resultsdb;
CREATE DATABASE resultsdb;
\connect resultsdb
CREATE TABLE resource_type (
	rt_id          INT,
        type           TEXT
);
CREATE TABLE resource_format (
	rf_id          INT,
        format         TEXT
);
CREATE TABLE organisations (
	id             INT,
        description    TEXT
);
CREATE TABLE resources (
	resource_id    INT,
	rtitle         TEXT,
	url            TEXT,
	type           INT,
	submitted_by   TEXT,
	author         TEXT,
	rorganisation  INT,
	date           DATE,
	format         INT,
	rdescription   TEXT,
	comments       TEXT,
	keywords       TEXT,
	copyright      INT,
	c_cost         FLOAT,
	c_description  TEXT,
	modified       DATE,
	programme      INT,
	project        INT,
	archive        INT,
	mail_count     INT,
	discussion_url TEXT
);
