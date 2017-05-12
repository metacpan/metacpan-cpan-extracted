/*

# $Id: package.sql,v 1.5 2003/07/19 10:40:16 oradb Exp $

Create a dummy package and procedure to debug

*/

CREATE OR REPLACE PACKAGE xpack IS
	PROCEDURE proc (
		xarg IN  VARCHAR2 DEFAULT 'default_proc_value',
		xret OUT NOCOPY VARCHAR2
	);
	FUNCTION func (
		xarg IN  VARCHAR2 DEFAULT 'default_func_value'
	) RETURN VARCHAR2;
END xpack;
/

CREATE OR REPLACE PACKAGE BODY xpack IS
	PROCEDURE proc (
		xarg IN  VARCHAR2 DEFAULT 'default_proc_value',
		xret OUT NOCOPY VARCHAR2
	) IS 
	BEGIN -- proc
		SELECT 'entering-the-packaged-procedure' INTO xret FROM dual;
		SELECT TO_CHAR(sysdate, 'YYYYMMDDHH24MISS') INTO xret FROM dual;
		SELECT 'leaving-the-packaged-procedure' INTO xret FROM dual;
	END proc;

	FUNCTION func (
		xarg IN  VARCHAR2 DEFAULT 'default_func_value'
	) RETURN VARCHAR2 IS
		xret VARCHAR2(64) DEFAULT xarg;
	BEGIN -- func
		SELECT 'in-the-packaged-function' INTO xret FROM dual;
		RETURN xret;
	END func;

END xpack;
/

