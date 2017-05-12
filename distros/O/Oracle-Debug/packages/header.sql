/*

# $Id: header.sql,v 1.6 2003/07/18 15:40:25 oradb Exp $

The header for the ORADB package .

The original version of this Oracle package was borrowed heavily (cut'n'paste) from:

	Rene Nyffenegger <rene.nyffenegger@adp-gmbh.ch>
	
at this location:

	http://www.adp-gmbh.ch/ora/plsql/debug.html

*/

create or replace package oradb as
--  function  target return varchar2;
--  procedure debug(debug_session_id in varchar2);
  procedure sync;

  procedure q;   
  procedure t;
  procedure L;
  procedure continue_(break_flags in number);
  procedure c;
  procedure B(breakpoint in binary_integer);
  procedure p(name in varchar2);
  procedure print_proginfo(prginfo dbms_debug.program_info);
  procedure print_runtime_info(runinfo dbms_debug.runtime_info);
  procedure print_runtime_info_with_source(
                 runinfo        dbms_debug.runtime_info, 
                 v_lines_before in number, 
                 v_lines_after  in number,
                 v_lines_width  in number);
  procedure self_check;
  procedure b(name in varchar2, line in number, owner in varchar2 default null);
  procedure n;
  procedure s;
  procedure r;
  function  str_for_namespace(nsp in binary_integer) return varchar2;
  function  str_for_reason_in_runtime_info(rsn in binary_integer) return varchar2;
  procedure target_running;
  procedure version;

--	PROCEDURE set_msg (
--		xdbid IN VARCHAR2,
--		xmsg  IN VARCHAR2	
--	);
  -- the following vars are used whenever continue returns and shows the lines around line
  p_cont_lines_before number;
  p_cont_lines_after  number;
  p_cont_lines_width  number;

	function namespace (xint IN BINARY_INTEGER) RETURN VARCHAR2; 
	function libunittype (xint IN BINARY_INTEGER) RETURN VARCHAR2;
	function breakpoint(xint IN BINARY_INTEGER) RETURN VARCHAR2;
	function errorcode(xint IN BINARY_INTEGER) RETURN VARCHAR2;

end oradb;
/
show errors;
