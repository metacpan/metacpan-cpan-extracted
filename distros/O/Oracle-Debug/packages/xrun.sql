/*

# $Id: xrun.sql,v 1.4 2003/07/18 15:40:25 oradb Exp $

Create a dummy procedure to run.

*/

CREATE OR REPLACE PROCEDURE xrun (	
	xarg IN  VARCHAR2 DEFAULT 'default_x_value'
) IS
	xret VARCHAR2(64) DEFAULT xarg;
BEGIN -- $$
	SELECT sysdate INTO xret FROM dual;
	xpack.proc(xarg, xret);
	SELECT 'end-of-xrun' INTO xret FROM dual;
END xrun;
/
