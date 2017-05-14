/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor l_c is
select u.name,l.name,l.userid,l.password,l.host from sys.link$ l,sys.user$ u
where u.name = ?
and l.name = ?
and l.owner# = u.user# 
order by u.name,l.name;
cursor p_c (c_user varchar2) is
select password from sys.dba_users where username = c_user;
alter_user sys.user$.name%TYPE;
prev_owner sys.user$.name%TYPE;
l_on sys.user$.name%TYPE;
l_db_link sys.link$.name%TYPE;
l_unm sys.link$.userid%TYPE;
l_password sys.link$.password%TYPE;
l_host sys.link$.host%TYPE;
user_password sys.dba_users.password%TYPE;
connect_pwd varchar2(10);
a_lin varchar2(80);
l_ln number;
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
l_ln := 0;
a_lin := '';
prev_owner := '@';
open l_c;
loop
fetch l_c into l_on,l_db_link,l_unm,l_password,l_host;
exit when l_c%NOTFOUND;
if l_on != prev_owner then
if prev_owner != '@' then
a_lin := wri(a_lin,' ',1);
if user_password != '<password>' then
a_lin := wri(a_lin,'alter user '||lower(prev_owner)||' identified by values '||chr(39)||user_password||chr(39)||';',1);
else
a_lin := wri(a_lin,'alter user '||lower(prev_owner)||' identified by <password>;',1);
end if;
end if;
if l_on = 'PUBLIC' then
open p_c('SYSTEM');
fetch p_c into user_password;
if p_c%NOTFOUND then
user_password := '<password>';
dbms_output.put_line( '*****> Warning:  Username '||'SYSTEM'||' not found in DBA_USERS!!');
end if;
else
open p_c(l_on);
fetch p_c into user_password;
if p_c%NOTFOUND then
user_password := '<password>';
dbms_output.put_line( '*****> Warning:  Username '||l_on||' not found in DBA_USERS!!');
end if;
end if;
close p_c;
a_lin := wri(a_lin,' ',1);
a_lin := wri(a_lin,'rem ----- Please Protect this Output !!! -----',1);
a_lin := wri(a_lin,' ',1);
if l_on = 'PUBLIC' then
alter_user := 'system';
else
alter_user := lower(l_on);
end if;
if user_password = '<password>' then
connect_pwd := user_password;
a_lin := wri(a_lin,'alter user '||alter_user||' identified by <password>;',1);
else
connect_pwd := 'xyzzy';
a_lin := wri(a_lin,'alter user '||alter_user||' identified by xyzzy;',1);
end if;
a_lin := wri(a_lin,'connect '||alter_user||'/'||connect_pwd,1);
if l_on = 'PUBLIC' then
prev_owner := 'system';
else
prev_owner := l_on;
end if;
end if;
if l_on = 'PUBLIC' then
a_lin := wri(a_lin,'CREATE PUBLIC DATABASE LINK '||l_db_link,1);
else
a_lin := wri(a_lin,'CREATE DATABASE LINK '||l_db_link,1);
end if;
a_lin := wri(a_lin,'    ',0);
if l_unm != ' ' then
a_lin := wri(a_lin,' connect to '||l_unm||' identified by '||l_password,0);
end if;
if l_host != ' ' then
a_lin := wri(a_lin,' using '||chr(39)||l_host||chr(39),0);
end if;
a_lin := wri(a_lin,';',1);
end loop;
close l_c;
if prev_owner != '@' then
a_lin := wri(a_lin,' ',1);
if user_password != '<password>' then
a_lin := wri(a_lin,'alter user '||lower(prev_owner)||' identified by values '||chr(39)||user_password||chr(39)||';',1);
else
a_lin := wri(a_lin,'alter user '||lower(prev_owner)||
' identified by <password>;',1);
end if;
end if;
a_lin := wri(a_lin,'exit',1);
end;
