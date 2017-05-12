/*

# $Id: body.sql,v 1.18 2003/07/18 15:40:25 oradb Exp $

The body for the ORADB package we use in both Oracle and Perl environments. 

*/

create or replace package body oradb as

  procedure q is
    runinfo dbms_debug.runtime_info;
    ret     binary_integer;
  begin
    ret := dbms_debug.continue(runinfo, dbms_debug.abort_execution, 0);
    -- ret := continue_(dbms_debug.abort_execution);
  end; --q

  procedure t is
    pkgs dbms_debug.backtrace_table;
    i    number;
  begin
    dbms_debug.print_backtrace(pkgs);
    i := pkgs.first();
    dbms_output.put_line('backtrace');
    while i is not null loop
      dbms_output.put_line('  ' || i || ': ' || pkgs(i).name || ' (' || pkgs(i).line# ||')');
      i := pkgs.next(i);
    end loop;
   exception
    when others then
     dbms_output.put_line('  backtrace exception: ' || sqlcode);
     dbms_output.put_line('                       ' || sqlerrm(sqlcode));
  end; -- t 
  
  procedure L is
    brkpts dbms_debug.breakpoint_table;
    i      number;

  begin
    dbms_debug.show_breakpoints(brkpts); 
    i := brkpts.first();
    dbms_output.put_line('breakpoints');
    while i is not null loop
      dbms_output.put_line('  ' || i || ': ' || brkpts(i).name || ' (' || brkpts(i).line# ||')');
      i := brkpts.next(i);
    end loop;
  end; -- L

  procedure continue_(break_flags in number) is
    runinfo dbms_debug.runtime_info;
    xec binary_integer;
  begin
    xec := dbms_debug.continue(
      runinfo,
        break_flags,
    --   dbms_debug.break_next_line     +  -- Break at next source line (step over calls). 
    --   dbms_debug.break_any_call      +  -- Break at next source line (step into calls). 
    --   dbms_debug.break_any_return    +
    --   dbms_debug.break_return        +
    --   dbms_debug.break_exception     +
    --   dbms_debug.break_handler       +
    --   dbms_debug.q     +
       0             +
       dbms_debug.info_getlineinfo   +
       dbms_debug.info_getbreakpoint +
       dbms_debug.info_getstackdepth +
       0);
  
     if xec = dbms_debug.success then
      -- dbms_output.put_line('  continue: success');
       -- print_runtime_info(runinfo);
       print_runtime_info_with_source(runinfo,p_cont_lines_before, p_cont_lines_after,p_cont_lines_width);
     else
			dbms_output.put_line('Error: ' || oradb.errorcode(xec));
     end if;
  end; -- continue_

  procedure c is
  begin
    continue_(0);
  end;  -- c

  procedure B(breakpoint in binary_integer) is
    ret binary_integer;
  begin
    ret := dbms_debug.delete_breakpoint(breakpoint);

    if ret = dbms_debug.success then
      dbms_output.put_line('  breakpoint deleted');
    elsif ret = dbms_debug.error_no_such_breakpt then
      dbms_output.put_line('  No such breakpoint exists');
    elsif ret = dbms_debug.error_idle_breakpt then
      dbms_output.put_line('  Cannot delete an unused breakpoint');
    elsif ret = dbms_debug.error_stale_breakpt then
      dbms_output.put_line('  The program unit was redefined since the breakpoint was set');
    else
      dbms_output.put_line('  Unknown error');
    end if;
  end; -- B

  procedure p(name in varchar2) is
    xec   binary_integer;
    val   varchar2(4000);
    frame number;
  begin
    frame := 0;
    xec := dbms_debug.get_value(name, frame, val, null);
    if xec = dbms_debug.success then
      dbms_output.put_line('  ' || name || ' = ' || val);
		else
			dbms_output.put_line('Error: ' || oradb.errorcode(xec));
    end if;
  end; -- p

/*
  procedure debug(debug_session_id in varchar2) is
  begin
    dbms_debug.attach_session(debug_session_id);
    p_cont_lines_before :=   5;
    p_cont_lines_after  :=   5;
    p_cont_lines_width  := 100;
    dbms_output.put_line('  debug session started?');
  end; -- debug

  function target return varchar2 as
    debug_session_id varchar2(20); 
  begin
    select dbms_debug.initialize into debug_session_id from dual;
		--
    dbms_debug.debug_on(TRUE, FALSE);
    -- dbms_debug.debug_on(TRUE, TRUE);
    return debug_session_id;
  end;  -- target
*/

  procedure print_proginfo(prginfo dbms_debug.program_info) as
  begin
    dbms_output.put_line('  Namespace:  ' || str_for_namespace(prginfo.namespace));
    dbms_output.put_line('  Name:       ' || prginfo.name);
    dbms_output.put_line('  owner:      ' || prginfo.owner);
    dbms_output.put_line('  dblink:     ' || prginfo.dblink);
    dbms_output.put_line('  Line#:      ' || prginfo.Line#);
    dbms_output.put_line('  lib unit:   ' || prginfo.libunittype);
    dbms_output.put_line('  entrypoint: ' || prginfo.entrypointname);
  end;  -- program_info

  procedure print_runtime_info(runinfo dbms_debug.runtime_info) as
    rsnt varchar2(40);
  begin

    rsnt := str_for_reason_in_runtime_info(runinfo.reason);
    --rsn := runinfo.reason;
    dbms_output.put_line('');
    dbms_output.put_line('Runtime Info');
    dbms_output.put_line('Line:          ' || runinfo.line#);
    dbms_output.put_line('Terminated:    ' || runinfo.terminated);
    dbms_output.put_line('Breakpoint:    ' || runinfo.breakpoint);
    dbms_output.put_line('Stackdepth     ' || runinfo.stackdepth);
    dbms_output.put_line('Reason         ' || rsnt);
    
    print_proginfo(runinfo.program);
  end; -- print_runtime_info

  procedure print_runtime_info_with_source(
    runinfo dbms_debug.runtime_info, 
    v_lines_before in number, 
    v_lines_after  in number,
    v_lines_width  in number) is
    prefix char(3);
    suffix varchar2(4000);
    line_printed char(1):='N';   
  begin
    for r in (select line, text
              from all_source 
              where 
                name  =  runinfo.program.name           and
                owner =  runinfo.program.owner          and
								type != 'PACKAGE' and
                line  >= runinfo.line# - 5 and --v_lines_before and
                line  <= runinfo.line# + 5 --v_lines_after  
              order by 
                line) loop
      if r.line = runinfo.line# then 
        prefix := ' * ';
      else
        prefix := '   ';
      end if;

      if length(r.text) > v_lines_width then
        suffix := substr(r.text,1,v_lines_width);
      else
        suffix := r.text;
      end if;

      suffix := translate(suffix,chr(10),' ');
      suffix := translate(suffix,chr(13),' ');
      
      dbms_output.put_line(prefix || suffix);

      line_printed := 'Y';
      end loop;

      if line_printed = 'N' then
        print_runtime_info(runinfo);
      end if;
  end;

  procedure self_check as
    ret binary_integer;
  begin
    dbms_debug.self_check(5);
  exception
    when dbms_debug.pipe_creation_failure     then
      dbms_output.put_line('  self_check: pipe_creation_failure');
    when dbms_debug.pipe_send_failure      then
      dbms_output.put_line('  self_check: pipe_send_failure');
    when dbms_debug.pipe_receive_failure   then
      dbms_output.put_line('  self_check: pipe_receive_failure');
    when dbms_debug.pipe_datatype_mismatch then
      dbms_output.put_line('  self_check: pipe_datatype_mismatch');
    when dbms_debug.pipe_data_error        then
      dbms_output.put_line('  self_check: pipe_data_error');
    when others then
      dbms_output.put_line('  self_check: unknown error');
  end; -- self_check

  procedure b (
    name in varchar2, line in number, owner in varchar2 default null) 
  as
    proginfo dbms_debug.program_info;
    ret      binary_integer;
    bp       binary_integer;
    fuzzy    binary_integer := 0;
    v_owner  varchar2(30);
  begin
    if owner is null then
      v_owner := user;
    else
      v_owner := owner;
    end if;
  
    proginfo.namespace      := dbms_debug.namespace_pkgspec_or_toplevel;
    proginfo.name   := UPPER(name);
    proginfo.owner  := v_owner;
    proginfo.dblink         := null;
    proginfo.line#  := line;
    proginfo.entrypointname := null;
  
    ret := dbms_debug.set_breakpoint(
      proginfo,
      proginfo.line#,
      bp,
			fuzzy -- not implemented by Oracle yet
			);
  
    if ret = dbms_debug.success then 
      dbms_output.put_line('  set_breakpoint: success');
    elsif ret = dbms_debug.error_illegal_line then
      dbms_output.put_line('  set_breakpoint: error_illegal_line');
    elsif ret = dbms_debug.error_bad_handle then
      dbms_output.put_line('  set_breakpoint: error_bad_handle');
    else
      dbms_output.put_line('  set_breakpoint: unknown error');
    end if;
  
    dbms_output.put_line('  breakpoint: ' || bp);
  end;  -- b 

  procedure n is
  begin
    continue_(dbms_debug.break_next_line);
  end; -- n
 
  procedure s is
  begin
    continue_(dbms_debug.break_any_call);
  end; -- s

  procedure r is
  begin
    continue_(dbms_debug.break_any_return);
  end; -- r

  function str_for_namespace(nsp in binary_integer) return varchar2 is
    nsps   varchar2(40);
  begin
    if nsp = dbms_debug.Namespace_cursor then
      nsps := 'cursor (anonymous block)';
    elsif nsp = dbms_debug.Namespace_pkgspec_or_toplevel then
      nsps := 'package, proc, func or obj type';
    elsif nsp = dbms_debug.Namespace_pkg_body then
      nsps := 'package body or type body';
    elsif nsp = dbms_debug.Namespace_trigger then
      nsps := 'triggers';
    else
      nsps := 'Unknown namespace';
    end if;

    return nsps;
  end; -- str_for_namespace

  function  str_for_reason_in_runtime_info(rsn in binary_integer) return varchar2 is
    rsnt varchar2(40);
  begin
    if rsn = dbms_debug.reason_none then
      rsnt := 'none';
    elsif rsn = dbms_debug.reason_interpreter_starting then
      rsnt := 'Interpreter is starting.';
    elsif rsn = dbms_debug.reason_breakpoint then
      rsnt := 'Hit a breakpoint';
    elsif rsn = dbms_debug.reason_enter then
      rsnt := 'Procedure entry';
    elsif rsn = dbms_debug.reason_return then
      rsnt := 'Procedure is about to return';
    elsif rsn = dbms_debug.reason_finish then
      rsnt := 'Procedure is finished';
    elsif rsn = dbms_debug.reason_line then
      rsnt := 'Reached a new line';
    elsif rsn = dbms_debug.reason_interrupt then
      rsnt := 'An interrupt occurred';
    elsif rsn = dbms_debug.reason_exception then
      rsnt := 'An exception was raised';
    elsif rsn = dbms_debug.reason_exit then
      rsnt := 'Interpreter is exiting (old form)';
    elsif rsn = dbms_debug.reason_knl_exit then
      rsnt := 'Kernel is exiting';
    elsif rsn = dbms_debug.reason_handler then
      rsnt := 'Start exception-handler';
    elsif rsn = dbms_debug.reason_timeout then
      rsnt := 'A timeout occurred';
    elsif rsn = dbms_debug.reason_instantiate then
      rsnt := 'Instantiation block';
    elsif rsn = dbms_debug.reason_abort then
      rsnt := 'Interpreter is aborting';
    else
      rsnt := 'Unknown reason';
    end if;
    return rsnt;
  end;  -- str_for_reason_in_runtime_info

  procedure sync as
    runinfo dbms_debug.runtime_info;
    ret     binary_integer;
  begin
    ret:=dbms_debug.synchronize(
      runinfo,
      0 +
      dbms_debug.info_getstackdepth +
      dbms_debug.info_getbreakpoint +
      dbms_debug.info_getlineinfo   +
      0
    );
    print_runtime_info(runinfo); -- anyway rjsf
    if ret = dbms_debug.success then 
      --dbms_output.put_line('  synchronize: success');
      print_runtime_info(runinfo);
    elsif ret = dbms_debug.error_timeout then
      dbms_output.put_line('  synchronize: error_timeout');
    elsif ret = dbms_debug.error_communication then
      dbms_output.put_line('  synchronize: error_communication');
    else
      dbms_output.put_line('  synchronize: unknown error');
    end if;
  end;  -- synchronize

  procedure target_running is
  begin
    if dbms_debug.target_program_running then
      dbms_output.put_line('  target is running');
    else
      dbms_output.put_line('  target is not running');
    end if;
  end; -- target_running

  procedure version as
    major binary_integer;
    minor binary_integer;
  begin
    dbms_debug.probe_version(major,minor);
    dbms_output.put_line('  probe version is: ' || major || '.' || minor);
  end; -- version

/*

Return the appropriate text string for the namespace

	varchar2 := oradb.namespace(binary_integer);

*/
 
	function namespace (xint IN BINARY_INTEGER) 
		RETURN VARCHAR2 IS
    xret VARCHAR2(64);
	BEGIN -- (Internal note: these map to the KGLN constants)
		IF xint = 0 THEN
			xret := 'CURSOR';
		ELSIF xint = 1 THEN
			xret := 'SPEC or TOPLEVEL';
		ELSIF xint = 2 THEN
			xret := 'PACKAGE BODY';
		ELSIF xint = 3 THEN
			xret := 'TRIGGER';
		ELSIF xint = 127 THEN
			xret := 'NONE';
		ELSE 
			IF xint IS NULL THEN
				xret := 'missing namespace: <' || xint || '> - talk to Oracle';
			ELSE
				xret := 'unrecognised namespace: ' || xint;
			END IF;
		END IF;
		RETURN xret;
  end namespace; -- 
 
	function libunittype (xint IN BINARY_INTEGER) 
		RETURN VARCHAR2 IS
    xret VARCHAR2(64);
	BEGIN -- (Internal note: these map to the KGLT constants)
		IF xint = 0 THEN
			xret := 'CURSOR';	
		ELSIF xint = 7 THEN
			xret := 'PROCEDURE';
		ELSIF xint = 8 THEN
			xret := 'FUNCTION';
		ELSIF xint = 9 THEN
			xret := 'PACKAGE';
		ELSIF xint = 11 THEN
			xret := 'PACKAGE_BODY';
		ELSIF xint = 12 THEN
			xret := 'TRIGGER';
		ELSIF xint = -1 THEN
			xret := 'UNKNOWN';
		ELSE 
			IF xint IS NULL THEN
				xret := 'missing library unit type: <' || xint || '> - talk to Oracle';
			ELSE
				xret := 'unrecognised library unit type: ' || xint;
			END IF;
		END IF;
		RETURN xret;
  end libunittype; -- 

	function breakpoint(xint IN BINARY_INTEGER) 
		RETURN VARCHAR2 IS
    xret VARCHAR2(64);
	BEGIN -- (Internal note: these map to the PBBPT constants)
		IF xint = 1 THEN
			xret := 'success';	
		ELSIF xint = 0 THEN
			xret := 'unused breakpoint';	
		ELSIF xint = 2 THEN
			xret := 'used breakpoint';	
		ELSIF xint = 4 THEN
			xret := 'disabled breakpoint';	
		ELSIF xint = 8 THEN
			xret := 'remote breakpoint';	
		ELSE 
			IF xint IS NULL THEN
				xret := 'missing breakpoint return code: <' || xint || '> - talk to Oracle'; 
			ELSE
				xret := 'unrecognised breakpoint return code: ' || xint;
			END IF;
		END IF;
		RETURN xret;
	end breakpoint;

	function errorcode(xint IN BINARY_INTEGER) 
		RETURN VARCHAR2 IS
    xret VARCHAR2(64);
		xoer VARCHAR2(64) := ' (non-informative Oracle error message)';
	BEGIN -- (Internal note: these map to the PBERR constants)
		IF xint = 0 THEN
			xret := 'success';	
		ELSIF xint = 1 THEN
			xret := 'no such frame';
		ELSIF xint = 2 THEN
			xret := 'no debug info';
		ELSIF xint = 3 THEN
			xret := 'no such object/variable/parameter/package/privileges' || xoer;
		ELSIF xint = 4 THEN
			xret := 'unknown type / garbled info';
		ELSIF xint = 18 THEN
			xret := 'unable to set entire index collection';
		ELSIF xint = 19 THEN
			xret := 'illegal collection index (v8)';
		ELSIF xint = 40 THEN
			xret := 'null atomical collection (v8)';
		ELSIF xint = 32 THEN
			xret := 'null value';
		ELSIF xint = 5 THEN
			xret := 'illegal value (constraint violation)';
		ELSIF xint = 6 THEN
			xret := 'illegal null (constraint violation)';
		ELSIF xint = 7 THEN
			xret := 'malformed value ';
		ELSIF xint = 8 THEN
			xret := 'unknown error' || xoer;
		ELSIF xint = 11 THEN
			xret := 'incomplete name (not a scalar lvalue)';
		ELSIF xint = 12 THEN
			xret := 'illegal breakpoint - no such line';
		ELSIF xint = 13 THEN
			xret := 'no such breakpoint';
		ELSIF xint = 14 THEN
			xret := 'unused (idle) breakpoint';
		ELSIF xint = 15 THEN
			xret := 'stale breakpoint';
		ELSIF xint = 16 THEN
			xret := 'unable to set breakpoint (bad handle)';
		ELSIF xint = 17 THEN
			xret := 'NYI (not yet implemented)';
		ELSIF xint = 27 THEN
			xret := 'deferred request - currently unused?';
		ELSIF xint = 28 THEN
			xret := 'internal Probe exception' || xoer;
		ELSIF xint = 29 THEN
			xret := 'pipe communication error';
		ELSIF xint = 31 THEN
			xret := 'timeout failure';
		ELSIF xint = 9 THEN
			xret := 'probe-run mismatch';
		ELSIF xint = 10 THEN
			xret := 'no rph' || xoer;
		ELSIF xint = 20 THEN
			xret := 'invalid Probe (version?)';
		ELSIF xint = 21 THEN
			xret := 'upierr' || xoer;
		ELSIF xint = 22 THEN
			xret := 'noasync' || xoer;
		ELSIF xint = 23 THEN
			xret := 'nologon' || xoer;
		ELSIF xint = 24 THEN
			xret := 'reinit' || xoer;
		ELSIF xint = 25 THEN
			xret := 'unrecognized' || xoer;
		ELSIF xint = 26 THEN
			xret := 'synch' || xoer;
		ELSIF xint = 30 THEN
			xret := 'incompatible' || xoer; 
		ELSE 
			IF xint IS NULL THEN
				xret := 'missing error code: <' || xint || '> - talk to Oracle'; 
			ELSE
				xret := 'unrecognised error code: ' || xint;
			END IF;
		END IF;
		RETURN xret;
	end errorcode;

end oradb;

/

show errors;
/
