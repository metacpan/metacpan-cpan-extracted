
/*

# $Id: table.sql,v 1.4 2003/07/09 15:54:30 oradb Exp $

Create oradb debugging table

*/

DROP TABLE oradb_table;
CREATE TABLE oradb_table (
	created   DATE DEFAULT sysdate,
	debugpid  VARCHAR2(32) NOT NULL,
	targetpid VARCHAR2(32) NOT NULL,
	sessionid VARCHAR2(32) NOT NULL,
	data      VARCHAR2(2056) DEFAULT ''
);

-- ALTER TABLE oradb_table ADD PRIMARY KEY 

