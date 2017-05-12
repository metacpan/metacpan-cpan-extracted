/*

# $Id: procedure.sql,v 1.1 2003/07/09 12:25:00 oradb Exp $

*/

CREATE OR REPLACE PROCEDURE xproc (	
	xarg IN  VARCHAR2 DEFAULT 'default_x_value'
) IS
	xret VARCHAR2(64) DEFAULT xarg;
BEGIN -- $$
	SELECT sysdate INTO xret FROM dual;
	xpack.proc(xarg);
END xproc;
/
