/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
t_on sys.dba_constraints.owner%TYPE;
t_cn sys.dba_constraints.constraint_name%TYPE;
t_ct sys.dba_constraints.constraint_type%TYPE;
t_tn sys.dba_constraints.table_name%TYPE;
t_sc sys.dba_constraints.search_condition%TYPE;
t_ro sys.dba_constraints.r_owner%TYPE;
t_rt sys.dba_constraints.table_name%TYPE;
t_rcn sys.dba_constraints.r_constraint_name%TYPE;
t_dr sys.dba_constraints.delete_rule%TYPE;
t_st sys.dba_constraints.status%TYPE;
t_ln number;
t_pn number;
t_np number;
t_cr varchar2(1);
t_iex varchar2(16);
t_nex varchar2(16);
t_tl number;
t_stp number;
t_x number;
t_bp number;
t_lp number;
t_sp number;
t_lf number;
t_bw number;
t_nl number;
t_of number;
t_os number;
t_ot number;
l number;
t_ol varchar2(2000);
t_bf varchar2(2000);
a_lin varchar2(2000);
my_lin varchar2(2000);
t_srb boolean;
t_stb number;
cursor c1 is
select dc1.owner,dc1.table_name,dc1.constraint_name,
dc1.constraint_type,dc1.search_condition,dc2.table_name r_table,
dc1.r_owner,dc1.r_constraint_name,dc1.delete_rule,dc1.status
from dba_constraints dc1,dba_constraints dc2
where dc1.r_constraint_name = dc2.constraint_name (+)
and dc1.owner like ?
and dc1.constraint_name like ?
order by decode(dc1.constraint_type,'P',0,'U',1,'R',2,3),dc1.owner,dc1.table_name,dc1.constraint_name,decode(dc1.constraint_type,'P',0,1);
function wri(x_ln in varchar2,x_str in varchar2,x_force in number)
return varchar2 is
begin
if length(x_ln) + length(x_str) > 80 then
t_ln := t_ln + 1;
dbms_output.put_line(x_ln);
if x_force = 0 then
return '    '||x_str;
else
t_ln := t_ln + 1;
if substr(x_ln,1,2) = '  ' then
dbms_output.put_line(x_str);
else
dbms_output.put_line('    '||x_str);
end if;
return '';
end if;
else
if x_force = 0 then
return x_ln||x_str;
else
t_ln := t_ln + 1;
dbms_output.put_line(x_ln||x_str);
return '';
end if;
end if;
end wri;
function brkline(x_ln in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
my_lin := x_ln;
t_tl := nvl(length(x_str),0);
t_stp := 1;
while t_stp <= t_tl
loop
t_bw := 0;
t_of := 0;
t_nl := 1;
t_srb := TRUE;
t_stb := t_stp;
while t_srb
loop
t_srb := FALSE;
t_bp := instr(x_str,' '||chr(9),t_stb);
if t_bp > 0 then
t_bf := ltrim(substr(x_str,t_stb,t_bp - t_stb + 1));
if nvl(t_bf,'@@xyzzy') = '@@xyzzy' then
t_bp := 0;
if t_stb + 2 < t_tl then
t_srb := TRUE;
t_stb := t_stb + 1;
end if;
end if;
end if;
end loop;
t_lp := instr(x_str,chr(10),t_stp);
t_lf := 0;
if (t_lp < t_bp or t_bp = 0) and t_lp > 0 then
t_bp := t_lp;
t_lf := 1;
end if;
t_sp := instr(x_str,';',t_stp);
if t_bp + t_lp = 0 or (t_bp > t_sp and t_sp > 0) then
if t_sp = 0 then
t_bp := t_stp + 80;
if t_bp > t_tl then
t_bp := t_tl + 1;
end if;
t_bw := 1;
t_nl := 0;
else
t_bp := t_sp + 1;
end if;
else
if t_lf = 0 then
t_bp := t_bp + 1;
t_of := 1;
else
t_of := 1;
end if;
end if;
if t_bp - t_stp > 80 then
t_bp := t_stp + 79;
if t_bp > t_tl then
t_bp := t_tl + 1;
end if;
t_bw := 1;
end if;
while t_bw = 1
loop
if t_bp > t_tl then
t_bw := 0;
exit;
end if;
if t_bp <= t_stp then
t_bp := t_stp + 79;
if t_bp > t_tl then
t_bp := t_tl + 1;
end if;
t_bw := 0;
exit;
end if;
if substr(x_str,t_bp,1) = ' ' then
t_bw := 0;
exit;
end if;
t_bp := t_bp - 1;
end loop;
t_x := t_bp - t_stp;
if t_x = 0 then
if t_of = 0 then
return my_lin;
end if;
else
t_ol := replace(substr(x_str,t_stp,t_x),chr(9),'        ');
t_os := 1;
l := length(t_ol);
if nvl(l,-1) = -1 then
return my_lin;
end if;
while t_os <= l
loop
if l >= t_os + 79 then
t_ot := 80;
else
t_ot := l - t_os + 1;
end if;
my_lin := wri(my_lin,substr(t_ol,t_os,t_ot),t_nl);
t_os := t_os + t_ot;
end loop;
end if;
t_stp := t_stp + t_x + t_of;
end loop;
return my_lin;
end brkline;
begin
t_ln := 0;
a_lin := '';
open c1;
loop
fetch c1 into t_on,t_tn,t_cn,t_ct,t_sc,t_rt,t_ro,t_rcn,t_dr,t_st;
exit when c1%notfound;
t_cr := 'n';
if t_ct = 'C' then
a_lin := wri(a_lin,'alter table ',0);
a_lin := wri(a_lin,t_on||'.'||t_tn,0);
t_np := instr(t_sc,' IS NOT NULL');
if t_np = 0 then
a_lin := wri(a_lin,' add (',0);
if substr(t_cn,1,5) != 'SYS_C' then
a_lin := wri(a_lin,'constraint ',0);
a_lin := wri(a_lin,t_cn,0);
a_lin := wri(a_lin,' ',0);
end if;
a_lin := wri(a_lin,'check(',0);
a_lin := brkline(a_lin,t_sc,0);
a_lin := wri(a_lin,')',0);
else
a_lin := wri(a_lin,' modify (',0);
a_lin := wri(a_lin,substr(t_sc,1,t_np - 1),0);
if substr(t_cn,1,5) != 'SYS_C' then
a_lin := wri(a_lin,' constraint ',0);
a_lin := wri(a_lin,t_cn,0);
end if;
a_lin := wri(a_lin,' NOT NULL',0);
end if;
if t_st = 'DISABLED' then
a_lin := wri(a_lin,' DISABLE',0);
end if;
a_lin := wri(a_lin,');',1);
end if;
if t_ct = 'P' then
a_lin := wri(a_lin,'alter table ',0);
a_lin := wri(a_lin,t_on||'.'||t_tn,0);
a_lin := wri(a_lin,' add constraint ',0);
a_lin := wri(a_lin,t_cn,0);
a_lin := wri(a_lin,' primary key (',0);
t_cr := 'Y';
end if;
if t_ct = 'R' then
a_lin := wri(a_lin,'alter table ',0);
a_lin := wri(a_lin,t_on||'.'||t_tn,0);
a_lin := wri(a_lin,' add constraint ',0);
a_lin := wri(a_lin,t_cn,0);
a_lin := wri(a_lin,' foreign key (',0);
t_cr := 'Y';
end if;
if t_ct = 'U' then
a_lin := wri(a_lin,'alter table ',0);
a_lin := wri(a_lin,t_on||'.'||t_tn,0);
a_lin := wri(a_lin,' add constraint ',0);
a_lin := wri(a_lin,t_cn,0);
a_lin := wri(a_lin,' unique (',0);
t_cr := 'Y';
end if;
if t_cr = 'Y' then
declare
c_owner sys.dba_cons_columns.owner%TYPE;
c_constraint_name sys.dba_cons_columns.constraint_name%TYPE;
c_table_name sys.dba_cons_columns.table_name%TYPE;
c_column_name sys.dba_cons_columns.column_name%TYPE;
c_position sys.dba_cons_columns.position%TYPE;
cursor c2 is
select owner,constraint_name,table_name,column_name,position
from dba_cons_columns
where owner = t_on and constraint_name = t_cn and table_name = t_tn
order by position;
begin
open c2;
loop
fetch c2 into c_owner,c_constraint_name,c_table_name,c_column_name,c_position;
exit when c2%notfound;
if c_position > 1 then
a_lin := wri(a_lin,',',0);
end if;
a_lin := wri(a_lin,chr(34)||c_column_name||chr(34),0);
end loop;
close c2;
end;
if t_ct = 'P' or t_ct = 'U' then
declare
tbs_name sys.dba_indexes.tablespace_name%TYPE;
ini_tr sys.dba_indexes.ini_trans%TYPE;
max_tr sys.dba_indexes.max_trans%TYPE;
init_ex sys.dba_indexes.initial_extent%TYPE;
next_ex sys.dba_indexes.next_extent%TYPE;
min_ex sys.dba_indexes.min_extents%TYPE;
max_ex sys.dba_indexes.max_extents%TYPE;
pct_inc sys.dba_indexes.pct_increase%TYPE;
pct_fr sys.dba_indexes.pct_free%TYPE;
missing_pri_index exception;
cursor c5 (t_cons varchar2) is
select tablespace_name,ini_trans,max_trans,initial_extent,next_extent,min_extents,max_extents,pct_increase,pct_free
from dba_indexes
where index_name = t_cons;
begin
open c5 (t_cn);
fetch c5 into tbs_name,ini_tr,max_tr,init_ex,next_ex,min_ex,max_ex,pct_inc,pct_fr;
if c5%notfound then
raise missing_pri_index;
end if;
close c5;
if mod(init_ex,1048576) = 0 then
t_iex := to_char(init_ex / 1048576)||'M';
elsif mod(init_ex,1024) = 0 then
t_iex := to_char(init_ex / 1024)||'K';
else
t_iex := to_char(init_ex);
end if;
if mod(next_ex,1048576) = 0 then
t_nex := to_char(next_ex / 1048576)||'M';
elsif mod(next_ex,1024) = 0 then
t_nex := to_char(next_ex / 1024)||'K';
else
t_nex := to_char(next_ex);
end if;
a_lin := wri(a_lin,') using index ',0);
a_lin := wri(a_lin,'tablespace ',0);
a_lin := wri(a_lin,tbs_name,0);
a_lin := wri(a_lin,' storage(',0);
a_lin := wri(a_lin,'initial ',0);
a_lin := wri(a_lin,t_iex,0);
a_lin := wri(a_lin,' next ',0);
a_lin := wri(a_lin,t_nex,0);
a_lin := wri(a_lin,' pctincrease ',0);
a_lin := wri(a_lin,pct_inc,0);
a_lin := wri(a_lin,' minextents ',0);
a_lin := wri(a_lin,min_ex,0);
a_lin := wri(a_lin,' maxextents ',0);
a_lin := wri(a_lin,max_ex,0);
a_lin := wri(a_lin,') ',0);
a_lin := wri(a_lin,'pctfree ',0);
a_lin := wri(a_lin,pct_fr,0);
a_lin := wri(a_lin,' initrans ',0);
a_lin := wri(a_lin,ini_tr,0);
a_lin := wri(a_lin,' maxtrans ',0);
a_lin := wri(a_lin,max_tr,0);
exception
when missing_pri_index then
close c5;
a_lin := wri(a_lin,')',0);
end;
if t_st = 'DISABLED' then
a_lin := wri(a_lin,' DISABLE',0);
end if;
a_lin := wri(a_lin,';',1);
end if;
if t_ct = 'R' then
declare
c_owner sys.dba_cons_columns.owner%TYPE;
c_table_name sys.dba_cons_columns.table_name%TYPE;
cursor c3 is
select owner,table_name
from dba_cons_columns
where owner = t_ro and constraint_name = t_rcn
order by position;
begin
open c3;
loop
fetch c3 into c_owner,c_table_name;
exit when c3%notfound;
end loop;
close c3;
a_lin := wri(a_lin,')',0);
a_lin := wri(a_lin,' references ',0);
a_lin := wri(a_lin,c_owner||'.'||
c_table_name,0);
end;
end if;
end if;
if t_ct = 'R' then
t_pn := 0;
declare
c_owner sys.dba_cons_columns.owner%TYPE;
c_constraint_name sys.dba_cons_columns.constraint_name%TYPE;
c_table_name sys.dba_cons_columns.table_name%TYPE;
c_column_name sys.dba_cons_columns.column_name%TYPE;
c_position sys.dba_cons_columns.position%TYPE;
cursor c4 is
select owner,constraint_name,
table_name,column_name,
position
from dba_cons_columns
where owner = t_ro and
constraint_name = t_rcn and table_name = t_rt
order by position;
begin
open c4;
loop
fetch c4 into c_owner,c_constraint_name,c_table_name,c_column_name,c_position;
exit when c4%notfound;
if c_position = 1 then
a_lin := wri(a_lin,' (',0);
a_lin := wri(a_lin,chr(34)||c_column_name||chr(34),0);
t_pn := 1;
else
a_lin := wri(a_lin,',',0);
a_lin := wri(a_lin,chr(34)||c_column_name||chr(34),0);
end if;
end loop;
close c4;
end;
if t_pn = 1 then
a_lin := wri(a_lin,')',0);
if t_dr = 'CASCADE' then
a_lin := wri(a_lin,' on delete cascade',0);
end if;
if t_st = 'DISABLED' then
a_lin := wri(a_lin,' DISABLE',0);
end if;
a_lin := wri(a_lin,';',1);
end if;
end if;
end loop;
close c1;
end;
