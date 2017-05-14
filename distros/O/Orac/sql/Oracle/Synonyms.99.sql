/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor syn_cursor is
select owner,synonym_name,table_owner,table_name,db_link
from sys.dba_synonyms
where owner like ?
and synonym_name like ?
order by owner,synonym_name;
l_on sys.dba_synonyms.owner%TYPE;
l_synonym_name sys.dba_synonyms.synonym_name%TYPE;
l_table_owner sys.dba_synonyms.table_owner%TYPE;
l_tn sys.dba_synonyms.table_name%TYPE;
l_db_link sys.dba_synonyms.db_link%TYPE;
l_ln number;
a_lin varchar2(80);
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 80 then
l_ln := l_ln + 1;
dbms_output.put_line(x_lin);
if x_force = 0 then
return '    '||x_str;
else
l_ln := l_ln + 1;
if substr(x_lin,1,2) = '  ' then
dbms_output.put_line(x_str);
else
dbms_output.put_line('    '||x_str);
end if;
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
open syn_cursor;
loop
fetch syn_cursor into l_on,l_synonym_name,l_table_owner,l_tn,l_db_link;
exit when syn_cursor%NOTFOUND;
if l_on = 'PUBLIC' then
a_lin := wri(a_lin,'CREATE PUBLIC SYNONYM ',0);
else
a_lin := wri(a_lin,'CREATE SYNONYM '||l_on||'.',0);
end if;
a_lin := wri(a_lin,l_synonym_name,0);
a_lin := wri(a_lin,' for ',0);
if l_db_link != ' ' then
a_lin := wri(a_lin,l_table_owner||'.'||l_tn||'@'||l_db_link,0);
else
a_lin := wri(a_lin,l_table_owner||'.'||l_tn,0);
end if;
a_lin := wri(a_lin,';',1);
end loop;
close syn_cursor;
a_lin := wri(a_lin,'',1);
end;
