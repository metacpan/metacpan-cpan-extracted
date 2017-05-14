/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor prof_cursor (c_gen_profile varchar2) is
select profile,resource_name,limit
from sys.dba_profiles
where profile = c_gen_profile
order by 1,2;
l_profile sys.dba_profiles.profile%TYPE;
l_resource_name sys.dba_profiles.resource_name%TYPE;
l_limit sys.dba_profiles.limit%TYPE;
l_ln number;
a_lin varchar2(80);
prev_profile sys.dba_profiles.profile%TYPE;
l_gen_profile sys.dba_profiles.profile%TYPE;
l_dummy sys.dba_profiles.profile%TYPE;
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 80 then
l_ln := l_ln + 1;
dbms_output.put_line( x_lin);
if x_force = 0 then
return '    '||x_str;
else
l_ln := l_ln + 1;
if substr(x_lin,1,2) = '  ' then
dbms_output.put_line( x_str);
else
dbms_output.put_line( '    '||x_str);
end if;
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
l_gen_profile := ? ;
l_dummy := ? ;
a_lin := '';
prev_profile := '@';
open prof_cursor (l_gen_profile);
loop
fetch prof_cursor into
l_profile,
l_resource_name,
l_limit;
exit when prof_cursor%NOTFOUND;
if prev_profile = l_profile then
a_lin := wri(a_lin,'    '||l_resource_name,0);
a_lin := wri(a_lin,' ',0);
a_lin := wri(a_lin,l_limit,1);
else
if prev_profile != '@' then
a_lin := wri(a_lin,';',1);
end if;
a_lin := wri(a_lin,'CREATE PROFILE ',0);
a_lin := wri(a_lin,l_profile,0);
a_lin := wri(a_lin,' limit',1);
a_lin := wri(a_lin,'    '||l_resource_name,0);
a_lin := wri(a_lin,' ',0);
a_lin := wri(a_lin,l_limit,1);
prev_profile := l_profile;
end if;
end loop;
close prof_cursor;
if prev_profile != '@' then
a_lin := wri(a_lin,';',1);
end if;
end;
