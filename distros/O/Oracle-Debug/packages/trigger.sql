/*

# $Id: trigger.sql,v 1.3 2003/07/09 15:54:30 oradb Exp $

*/

CREATE OR REPLACE TRIGGER xtrig
	BEFORE INSERT 
	ON oradb_table FOR EACH ROW
DECLARE -- PRAGMA AUTONOMOUS_TRANSACTION;
    xret  VARCHAR2(64);
BEGIN -- (INSERT|UPDAT|DELETE)ING
	NULL;
	IF 1 = 0 THEN
		:new.data := 'non-triggered data';
	ELSIF 1 = 1 THEN
		:new.data := 'triggered data';
	END IF;
END;
/


