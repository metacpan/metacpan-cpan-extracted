/*

# $Id: function.sql,v 1.2 2003/07/09 14:12:40 oradb Exp $

*/

CREATE OR REPLACE FUNCTION xfunc (	
	xarg IN  VARCHAR2 DEFAULT 'default_x_value'
) RETURN VARCHAR2 IS
	xret VARCHAR2(64) DEFAULT xarg;
BEGIN -- $$
	SELECT sysdate INTO xret FROM dual;
	xret := xpack.func(xarg);
	RETURN xret;
END xfunc;
/
