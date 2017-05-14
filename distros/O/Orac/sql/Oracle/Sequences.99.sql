/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor seq_cursor is
select sequence_owner,sequence_name,min_value,max_value,increment_by,cycle_flag,order_flag,cache_size
from sys.dba_sequences
where sequence_owner = ?
and sequence_name = ?
order by 1,2;
l_sequence_owner sys.dba_sequences.sequence_owner%TYPE;
l_sequence_name sys.dba_sequences.sequence_name%TYPE;
l_min_value sys.dba_sequences.min_value%TYPE;
l_max_value sys.dba_sequences.max_value%TYPE;
l_increment_by sys.dba_sequences.increment_by%TYPE;
l_cycle_flag sys.dba_sequences.cycle_flag%TYPE;
l_order_flag sys.dba_sequences.order_flag%TYPE;
l_cache_size sys.dba_sequences.cache_size%TYPE;
l_ln number;
text_length number;
startp number;
xchar number;
break_pos number;
lf_pos number;
semi_pos number;
lf_break number;
backwords number;
new_line number;
offset number;
out_start number;
out_len number;
l number;
bef_chars varchar2(80);
out_line varchar2(640);
a_lin varchar2(80);
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 80 then
l_ln := l_ln + 1;
dbms_output.put_line(x_lin);
if x_force = 0 then
return x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_str);
return '';
end if;
else
if x_force = 0 then
return x_lin||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_lin||x_str);
return '';
end if;
end if;
end wri;
begin
a_lin := '';
l_ln := 0;
open seq_cursor;
loop
fetch seq_cursor into l_sequence_owner,l_sequence_name,l_min_value,l_max_value,l_increment_by,l_cycle_flag,l_order_flag,l_cache_size;
exit when seq_cursor%NOTFOUND;
a_lin := wri(a_lin,'create sequence ',0);
a_lin := wri(a_lin,l_sequence_owner||'.'||
l_sequence_name,1);
a_lin := wri(a_lin,' increment by '||
to_char(l_increment_by),0);
if l_increment_by > 0 then
if l_min_value = 1 then
a_lin := wri(a_lin,' nominvalue',0);
else
a_lin := wri(a_lin,' minvalue '||
to_char(l_min_value),0);
end if;
if l_max_value > power(10,26) then
a_lin := wri(a_lin,' nomaxvalue',0);
else
a_lin := wri(a_lin,' maxvalue '||
to_char(l_max_value),0);
end if;
else
if l_min_value < -1 * POWER(10,25) then
a_lin := wri(a_lin,' nominvalue',0);
else
a_lin := wri(a_lin,' minvalue '||
to_char(l_min_value),0);
end if;
if l_max_value = -1 then
a_lin := wri(a_lin,' nomaxvalue',0);
else
a_lin := wri(a_lin,' maxvalue '||
to_char(l_max_value),0);
end if;
end if;
if l_cycle_flag = 'Y' then
a_lin := wri(a_lin,' cycle',0);
else
a_lin := wri(a_lin,' nocycle',0);
end if;
a_lin := wri(a_lin,' cache '||to_char(l_cache_size),0);
if l_order_flag = 'Y' then
a_lin := wri(a_lin,' order',0);
else
a_lin := wri(a_lin,' noorder',0);
end if;
a_lin := wri(a_lin,';',1);
end loop;
close seq_cursor;
end;
