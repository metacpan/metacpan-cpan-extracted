/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor s_c is
select s.owner,s.name,s.table_name,s.type,s.next,s.start_with,s.query,t.pct_free,t.pct_used,t.ini_trans,t.max_trans,t.tablespace_name,t.initial_extent,t.next_extent,t.min_extents,t.max_extents,t.pct_increase
from sys.dba_snapshots s,sys.dba_tables t
where s.owner = ?
and s.name = ?
and s.owner = t.owner and s.table_name = t.table_name
order by s.table_name;
l_on sys.dba_snapshots.owner%TYPE;
l_nm sys.dba_snapshots.name%TYPE;
l_tn sys.dba_snapshots.table_name%TYPE;
l_type sys.dba_snapshots.type%TYPE;
l_next sys.dba_snapshots.next%TYPE;
l_stwth sys.dba_snapshots.start_with%TYPE;
l_qy sys.dba_snapshots.query%TYPE;
l_ptf sys.dba_tables.pct_free%TYPE;
l_ptu sys.dba_tables.pct_used%TYPE;
l_initrn sys.dba_tables.ini_trans%TYPE;
l_mxtrn sys.dba_tables.max_trans%TYPE;
l_tbsp sys.dba_tables.tablespace_name%TYPE;
l_iex sys.dba_tables.initial_extent%TYPE;
l_nexex sys.dba_tables.next_extent%TYPE;
l_min_extents sys.dba_tables.min_extents%TYPE;
l_maxexs sys.dba_tables.max_extents%TYPE;
l_pctin sys.dba_tables.pct_increase%TYPE;
l_inixsz varchar2(16);
l_nxexsz varchar2(16);
l_stdt_st varchar2(30);
l_ln number;
l_txtl number;
startp number;
xchar number;
l_brp number;
lf_pos number;
semi_pos number;
lf_break number;
backwords number;
new_line number;
offset number;
out_start number;
out_len number;
l number;
out_line varchar2(2000);
bef_chars varchar2(2000);
a_lin varchar2(80);
my_lin varchar2(2000);
search_for_break boolean;
start_break_search number;
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
function brkline(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
my_lin := x_lin;
l_txtl := nvl(length(x_str),0);
startp := 1;
while startp <= l_txtl
loop
backwords := 0;
offset := 0;
new_line := 1;
search_for_break := TRUE;
start_break_search := startp;
while search_for_break
loop
search_for_break := FALSE;
l_brp := instr(x_str,' '||chr(9),start_break_search);
if l_brp > 0 then
bef_chars := ltrim(substr(x_str,
start_break_search,
l_brp - start_break_search +
1));
if nvl(bef_chars,'@@xyzzy') = '@@xyzzy' then
l_brp := 0;
if start_break_search + 2 < l_txtl then
search_for_break := TRUE;
start_break_search := start_break_search + 1;
end if;
end if;
end if;
end loop;
lf_pos := instr(x_str,chr(10),startp);
lf_break := 0;
if (lf_pos < l_brp or l_brp = 0) and lf_pos > 0 then
l_brp := lf_pos;
lf_break := 1;
end if;
semi_pos := instr(x_str,';',startp);
if l_brp + lf_pos = 0 or (l_brp > semi_pos and semi_pos > 0) then
if semi_pos = 0 then
l_brp := startp + 80;
if l_brp > l_txtl then
l_brp := l_txtl + 1;
end if;
backwords := 1;
new_line := 0;
else
l_brp := semi_pos + 1;
end if;
else
if lf_break = 0 then
l_brp := l_brp + 1;
offset := 1;
else
offset := 1;
end if;
end if;
if l_brp - startp > 80 then
l_brp := startp + 79;
if l_brp > l_txtl then
l_brp := l_txtl + 1;
end if;
backwords := 1;
end if;
while backwords = 1
loop
if l_brp > l_txtl then
backwords := 0;
exit;
end if;
if l_brp <= startp then
l_brp := startp + 79;
if l_brp > l_txtl then
l_brp := l_txtl + 1;
end if;
backwords := 0;
exit;
end if;
if substr(x_str,l_brp,1) = ' ' then
backwords := 0;
exit;
end if;
l_brp := l_brp - 1;
end loop;
xchar := l_brp - startp;
if xchar = 0 then
if offset = 0 then
return my_lin;
end if;
else
out_line := replace(substr(x_str,startp,xchar),chr(9),'        ');
out_start := 1;
l := length(out_line);
if nvl(l,-1) = -1 then
return my_lin;
end if;
while out_start <= l
loop
if l >= out_start + 79 then
out_len := 80;
else
out_len := l - out_start + 1;
end if;
my_lin := wri(my_lin,
substr(out_line,out_start,
out_len),new_line);
out_start := out_start + out_len;
end loop;
end if;
startp := startp + xchar + offset;
end loop;
return my_lin;
end brkline;
begin
a_lin := '';
l_ln := 0;
open s_c;
loop
fetch s_c into l_on,l_nm,l_tn,l_type,l_next,l_stwth,l_qy,l_ptf,l_ptu,l_initrn,l_mxtrn,l_tbsp,l_iex,l_nexex,l_min_extents,l_maxexs,l_pctin;
exit when s_c%NOTFOUND;
a_lin := wri(a_lin,'create snapshot '||l_on,0);
a_lin := wri(a_lin,'.'||l_nm,1);
a_lin := wri(a_lin,' PCTFREE '||to_char(l_ptf),0);
a_lin := wri(a_lin,' PCTUSED '||to_char(l_ptu),0);
a_lin := wri(a_lin,' INITRANS '||to_char(l_initrn),0);
a_lin := wri(a_lin,' MAXTRANS '||to_char(l_mxtrn),0);
a_lin := wri(a_lin,' TABLESPACE '||l_tbsp,1);
a_lin := wri(a_lin,' STORAGE (',0);
if mod(l_iex,1048576) = 0 then
l_inixsz :=
to_char(l_iex / 1048576)||'M';
elsif mod(l_iex,1024) = 0 then
l_inixsz :=
to_char(l_iex / 1024)||'K';
else
l_inixsz := to_char(l_iex);
end if;
if mod(l_nexex,1048576) = 0 then
l_nxexsz :=
to_char(l_nexex / 1048576)||'M';
elsif mod(l_nexex,1024) = 0 then
l_nxexsz :=
to_char(l_nexex / 1024)||'K';
else
l_nxexsz := to_char(l_nexex);
end if;
a_lin := wri(a_lin,' INITIAL '||l_inixsz,0);
a_lin := wri(a_lin,' NEXT '||l_nxexsz,0);
a_lin := wri(a_lin,' MINEXTENTS '||to_char(l_min_extents),0);
a_lin := wri(a_lin,' MAXEXTENTS '||to_char(l_maxexs),0);
a_lin := wri(a_lin,' PCTINCREASE '||to_char(l_pctin),0);
a_lin := wri(a_lin,')',1);
a_lin := wri(a_lin,' refresh',0);
if l_type = ' ' then
l_type := 'FORCE';
end if;
a_lin := wri(a_lin,' '||l_type,0);
l_stdt_st := to_char(l_stwth,'DD-MON-YY');
if nvl(l_stdt_st,' ') != ' ' then
a_lin := wri(a_lin,' start with '||l_stdt_st,0);
end if;
if nvl(l_next,' ') != ' ' then
a_lin := brkline(a_lin,' next '||l_next,0);
end if;
a_lin := wri(a_lin,' as ',0);
a_lin := brkline(a_lin,l_qy,0);
a_lin := wri(a_lin,';',1);
end loop;
close s_c;
exception
when others then
raise_application_error(-20000,'Unexpected error on '||l_on||'.'||l_tn||': '||to_char(SQLCODE)||' - Aborting...');
end;
