/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor snap_log_cursor is
select s.log_owner,s.master,t.pct_free,t.pct_used,t.ini_trans,t.max_trans,t.tablespace_name,t.initial_extent,t.next_extent,t.min_extents,t.max_extents,t.pct_increase
from sys.dba_snapshot_logs s,sys.dba_tables t
where s.log_owner = ?
and s.master = ?
and s.log_owner = t.owner and s.log_table = t.table_name
order by s.log_owner,s.master,s.log_table;
l_log_owner sys.dba_snapshot_logs.log_owner%TYPE;
l_master sys.dba_snapshot_logs.master%TYPE;
l_pct_free sys.dba_tables.pct_free%TYPE;
l_pct_used sys.dba_tables.pct_used%TYPE;
l_ini_trans sys.dba_tables.ini_trans%TYPE;
l_max_trans sys.dba_tables.max_trans%TYPE;
l_tbsp sys.dba_tables.tablespace_name%TYPE;
l_iex sys.dba_tables.initial_extent%TYPE;
l_nexex sys.dba_tables.next_extent%TYPE;
l_min_extents sys.dba_tables.min_extents%TYPE;
l_maxexs sys.dba_tables.max_extents%TYPE;
l_pctin sys.dba_tables.pct_increase%TYPE;
initial_extent_size varchar2(16);
next_extent_size varchar2(16);
l_ln number;
a_lin varchar2(80);
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 80 then
l_ln := l_ln + 1;
dbms_output.put_line( x_lin);
if x_force = 0 then
return x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line( x_str);
return '';
end if;
else
if x_force = 0 then
return x_lin||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line( x_lin||x_str);
return '';
end if;
end if;
end wri;
begin
a_lin := '';
l_ln := 0;
open snap_log_cursor;
loop
fetch snap_log_cursor into l_log_owner,l_master,l_pct_free,l_pct_used,l_ini_trans,l_max_trans,l_tbsp,l_iex,l_nexex,l_min_extents,l_maxexs,l_pctin;
exit when snap_log_cursor%NOTFOUND;
a_lin := wri(a_lin,'create snapshot log on ',0);
a_lin := wri(a_lin,l_log_owner||'.'||l_master,1);
a_lin := wri(a_lin,' PCTFREE '||to_char(l_pct_free),0);
a_lin := wri(a_lin,' PCTUSED '||to_char(l_pct_used),0);
a_lin := wri(a_lin,' INITRANS '||to_char(l_ini_trans),0);
a_lin := wri(a_lin,' MAXTRANS '||to_char(l_max_trans),0);
a_lin := wri(a_lin,' TABLESPACE '||l_tbsp,1);
a_lin := wri(a_lin,' STORAGE (',0);
if mod(l_iex,1048576) = 0 then
initial_extent_size :=
to_char(l_iex / 1048576)||'M';
elsif mod(l_iex,1024) = 0 then
initial_extent_size :=
to_char(l_iex / 1024)||'K';
else
initial_extent_size := to_char(l_iex);
end if;
if mod(l_nexex,1048576) = 0 then
next_extent_size :=
to_char(l_nexex / 1048576)||'M';
elsif mod(l_nexex,1024) = 0 then
next_extent_size :=
to_char(l_nexex / 1024)||'K';
else
next_extent_size := to_char(l_nexex);
end if;
a_lin := wri(a_lin,' INITIAL '||initial_extent_size,0);
a_lin := wri(a_lin,' NEXT '||next_extent_size,0);
a_lin := wri(a_lin,' MINEXTENTS '||to_char(l_min_extents),0);
a_lin := wri(a_lin,' MAXEXTENTS '||to_char(l_maxexs),0);
a_lin := wri(a_lin,' PCTINCREASE '||to_char(l_pctin),0);
a_lin := wri(a_lin,');',1);
end loop;
close snap_log_cursor;
exception
when others then
raise_application_error(-20000,'Unexpected error on '||l_log_owner||'.'||l_master||': '||to_char(SQLCODE)||' - Aborting...');
end;
