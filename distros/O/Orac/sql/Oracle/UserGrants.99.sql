/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

Declare
--
   cursor p_c (c_user varchar2) is
      select password 
      from sys.dba_users 
      where username = c_user;
--
   cursor o_c (c_gen_role varchar2) is
      select grantee,owner,table_name,privilege,decode(grantable,'YES',' WITH GRANT OPTION;',';')
      from sys.dba_tab_privs
      where grantee like c_gen_role
      order by 2,3,1,4;
--
   cursor c_c (c_gen_role varchar2) is
      select grantee,owner,table_name,column_name,privilege,
      decode(grantable,'YES',' WITH GRANT OPTION;',';')
      from sys.dba_col_privs
      where grantee like c_gen_role
      order by 2,3,4,5,1;
--
   cursor s_c (c_gen_role varchar2) is
      select grantee,privilege,
             decode(admin_option,'YES',' WITH ADMIN OPTION;',';')
      from sys.dba_sys_privs
      where grantee like c_gen_role
      order by 1,2;
--
   cursor r_c (c_gen_role varchar2) is
      select grantee,granted_role,
             decode(admin_option,'YES',' WITH ADMIN OPTION;',';')
      from sys.dba_role_privs
      where grantee like c_gen_role
      order by 1,2;
--
l_gen_role sys.dba_roles.role%TYPE;
l_dummy sys.dba_roles.role%TYPE;
--
l_gt sys.dba_tab_privs.grantee%TYPE;
l_on sys.dba_tab_privs.owner%TYPE;
l_tn sys.dba_tab_privs.table_name%TYPE;
l_cn sys.dba_col_privs.column_name%TYPE;
l_pv sys.dba_tab_privs.privilege%TYPE;
l_gnrole sys.dba_role_privs.granted_role%TYPE;
l_grntl varchar2(19);
l_string varchar2(80);
l_ln number;
a_lin varchar2(80);
prev_grantee sys.dba_tab_privs.grantee%TYPE;
prev_own sys.dba_tab_privs.owner%TYPE;
alter_user sys.dba_tab_privs.owner%TYPE;
prev_owner sys.dba_tab_privs.owner%TYPE;
prev_table_name sys.dba_tab_privs.table_name%TYPE;
prev_column_name sys.dba_col_privs.column_name%TYPE;
prev_grantable varchar2(19);
privs varchar2(100);
user_password sys.dba_users.password%TYPE;
connect_pwd varchar2(10);
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
l_gen_role := ? ;
l_dummy := ? ;
a_lin := '';
l_ln := 0;
prev_grantee := '@';
prev_own := '@';
prev_owner := '';
prev_table_name := '';
prev_grantable := '';
privs := '';
a_lin := wri(a_lin,'rem *** Object Privileges ***',1);
a_lin := '';
open o_c (l_gen_role);
loop
fetch o_c into l_gt,l_on,l_tn,l_pv,l_grntl;
exit when o_c%NOTFOUND;
if prev_grantee = l_gt and prev_owner = l_on and
prev_table_name = l_tn and
prev_grantable = l_grntl then
if instr(privs,l_pv) = 0 then
a_lin := wri(a_lin,','||l_pv,0);
privs := privs||l_pv;
end if;
else
if prev_grantee != '@' then
a_lin := wri(a_lin,' ON',0);
a_lin := wri(a_lin,' '||prev_owner||'.'||prev_table_name,0);
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
if l_on != prev_own then
if prev_own != '@' then
a_lin := wri(a_lin,'rem connect system/xyzzy',1);
if user_password != '<password>' then
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by'||' values '||chr(39)||user_password||chr(39)||';',1);
else
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by'||' <password>;',1);
end if;
end if;
open p_c(l_on);
fetch p_c into user_password;
if p_c%NOTFOUND then
user_password := '<password>';
dbms_output.put_line( '*****> Warning:  Username '||l_on||' not found in DBA_USERS!!');
end if;
close p_c;
a_lin := wri(a_lin,' ',1);
a_lin := wri(a_lin,'rem ----------------------------',1);
a_lin := wri(a_lin,' ',1);
alter_user := lower(l_on);
if user_password = '<password>' then
connect_pwd := user_password;
a_lin := wri(a_lin,'alter user '||alter_user||' identified by <password>;',1);
else
connect_pwd := 'xyzzy';
a_lin := wri(a_lin,'alter user '||alter_user||' identified by xyzzy;',1);
end if;
a_lin := wri(a_lin,'connect '||alter_user||'/'||connect_pwd,1);
prev_own := l_on;
end if;
a_lin := wri(a_lin,'GRANT ',0);
a_lin := wri(a_lin,l_pv,0);
prev_grantee := l_gt;
prev_owner := l_on;
prev_table_name := l_tn;
prev_grantable := l_grntl;
privs := l_pv;
end if;
end loop;
close o_c;
if prev_grantee != '@' then
a_lin := wri(a_lin,' ON',0);
a_lin := wri(a_lin,' '||prev_owner||'.'||prev_table_name,0);
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
if prev_own != '@' then
a_lin := wri(a_lin,'connect system/xyzzy',1);
if user_password != '<password>' then
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by values '||chr(39)||user_password||chr(39)||';',1);
else
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by <password>;',1);
end if;
end if;
a_lin := wri(a_lin,'rem *** Column Privileges ***',1);
a_lin := '';
prev_grantee := '@';
prev_own := '@';
prev_owner := '';
prev_table_name := '';
prev_column_name := '';
prev_grantable := '';
privs := '';
open c_c (l_gen_role);
loop
fetch c_c into l_gt,l_on,l_tn,l_cn,l_pv,l_grntl;
exit when c_c%NOTFOUND;
if prev_grantee = l_gt and prev_owner = l_on and
prev_table_name = l_tn and
prev_column_name = l_cn and
prev_grantable = l_grntl then
if instr(privs,l_pv) = 0 then
a_lin := wri(a_lin,','||l_pv,0);
privs := privs||l_pv;
end if;
else
if prev_grantee != '@' then
a_lin := wri(a_lin,' ON',0);
a_lin := wri(a_lin,' '||prev_owner||'.'||prev_table_name,0);
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
if l_on != prev_own then
if prev_own != '@' then
a_lin := wri(a_lin,'connect system/xyzzy',1);
if user_password != '<password>' then
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by'||' values '||chr(39)||user_password||chr(39)||';',1);
else
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by'||' <password>;',1);
end if;
end if;
open p_c(l_on);
fetch p_c into user_password;
if p_c%NOTFOUND then
user_password := '<password>';
dbms_output.put_line( '*****> Warning:  Username '||l_on||' not found in DBA_USERS!!');
end if;
close p_c;
a_lin := wri(a_lin,' ',1);
a_lin := wri(a_lin,'rem ----------------------------',1);
a_lin := wri(a_lin,' ',1);
alter_user := lower(l_on);
if user_password = '<password>' then
connect_pwd := user_password;
a_lin := wri(a_lin,'alter user '||alter_user||' identified by <password>;',1);
else
connect_pwd := 'xyzzy';
a_lin := wri(a_lin,'alter user '||alter_user||' identified by xyzzy;',1);
end if;
a_lin := wri(a_lin,'connect '||alter_user||'/'||connect_pwd,1);
prev_own := l_on;
end if;
a_lin := wri(a_lin,'GRANT ',0);
a_lin := wri(a_lin,l_pv,0);
a_lin := wri(a_lin,' ('||l_cn||')',0);
prev_grantee := l_gt;
prev_owner := l_on;
prev_table_name := l_tn;
prev_column_name := l_cn;
prev_grantable := l_grntl;
privs := l_pv;
end if;
end loop;
close c_c;
if prev_grantee != '@' then
a_lin := wri(a_lin,' ON',0);
a_lin := wri(a_lin,' '||prev_owner||'.'||prev_table_name,0);
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
if prev_own != '@' then
a_lin := wri(a_lin,'connect system/xyzzy',1);
if user_password != '<password>' then
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by values '||chr(39)||user_password||chr(39)||';',1);
else
a_lin := wri(a_lin,'alter user '||lower(prev_own)||' identified by <password>;',1);
end if;
end if;
a_lin := wri(a_lin,'rem *** System Privileges ***',1);
a_lin := '';
a_lin := wri(a_lin,'connect system/xyzzy',1);
prev_grantee := '@';
prev_grantable := '';
open s_c (l_gen_role);
loop
fetch s_c into l_gt,l_pv,l_grntl;
exit when s_c%NOTFOUND;
if prev_grantee = l_gt and prev_grantable = l_grntl then
a_lin := wri(a_lin,','||l_pv,0);
else
if prev_grantee != '@' then
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
a_lin := wri(a_lin,'GRANT ',0);
a_lin := wri(a_lin,l_pv,0);
prev_grantee := l_gt;
prev_grantable := l_grntl;
end if;
end loop;
close s_c;
if prev_grantee != '@' then
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
a_lin := wri(a_lin,'rem *** Role Privileges ***',1);
a_lin := '';
prev_grantee := '@';
prev_grantable := '';
open r_c (l_gen_role);
loop
fetch r_c into l_gt,l_gnrole,l_grntl;
exit when r_c%NOTFOUND;
if prev_grantee = l_gt and prev_grantable = l_grntl then
a_lin := wri(a_lin,','||l_gnrole,0);
else
if prev_grantee != '@' then
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
a_lin := wri(a_lin,'GRANT ',0);
a_lin := wri(a_lin,l_gnrole,0);
prev_grantee := l_gt;
prev_grantable := l_grntl;
end if;
end loop;
close r_c;
if prev_grantee != '@' then
a_lin := wri(a_lin,' TO',0);
a_lin := wri(a_lin,' '||prev_grantee,0);
a_lin := wri(a_lin,prev_grantable,1);
end if;
end;
