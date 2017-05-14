/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

select '/* a */' step, 'create tablespace '||T.tablespace_name||chr(10)||
'datafile '''||F.file_name||''' size '|| to_char(F.bytes/1048576)||'M'||chr(10)||
'default storage (Initial '||to_char(T.initial_extent)||
' next '||to_char(T.next_extent)||' minextents '||to_char(T.min_extents)||chr(10)|| '         maxextents '||
to_char(T.max_extents)||' pctincrease '||to_char(T.pct_increase)||') online ;'||chr(10)||chr(10) creation_sql
from sys.dba_data_files F,sys.dba_tablespaces T
where T.tablespace_name = F.tablespace_name
and T.tablespace_name != 'SYSTEM'
and F.file_id = ( select min(file_id) from sys.dba_data_files where tablespace_name = T.tablespace_name )
union
select '/* b */' step,'alter tablespace '||T.tablespace_name||chr(10)||'add datafile '''||F.file_name||''' size '||
to_char(F.bytes/1048576)||'M ;'||chr(10)||chr(10) creation_sql
from sys.dba_data_files F,sys.dba_tablespaces T
where T.tablespace_name = F.tablespace_name
and F.file_id != ( select min(file_id)
from sys.dba_data_files
where tablespace_name = T.tablespace_name )
union
select '/* c */' step,
'create role '||role||decode(password_required,'N',' not identified ;',' identified externally ;')||chr(10) creation_sql
from sys.dba_roles
union
select distinct '/* d */' step,'create profile '||profile||' limit '||';'||chr(10) creation_sql
from sys.dba_profiles
union
select '/* e */' step,'alter role '||profile||' limit '||resource_name||' '||limit||';'||chr(10) creation_sql
from sys.dba_profiles
where limit != 'DEFAULT'
and ( profile != 'DEFAULT' or limit != 'UNLIMITED')
union
select '/* f */' step,'create USER '||username||' identified by XXXXX '||chr(10)||' default tablespace '||default_tablespace||
' temporary tablespace '||temporary_tablespace||chr(10)||' quota unlimited on '||default_tablespace||' '||
' quota unlimited on '||temporary_tablespace||';'||chr(10)||chr(10) creation_sql
from sys.dba_users
where username not in ('SYSTEM','SYS','_NEXT_USER','PUBLIC')
union
select '/* g */' step,'rem ----- Please protect this output carefully!!!-----'||chr(10)||
'alter USER '||username||' identified by values '''||password||''';'||chr(10) creation_sql
from sys.dba_users
where username not in ('SYSTEM','SYS','_NEXT_USER','PUBLIC')
and password != 'EXTERNAL'
union
select '/* h */' step,'alter USER '||username||' quota '||decode(max_bytes,-1,'unlimited',
to_char(max_bytes/1024)||' K')||' on tablespace '||tablespace_name||';'||chr(10) creation_sql
from sys.dba_ts_quotas
union
select '/* i */' step,'grant '||S.name||' to '||U.username||';'||chr(10) creation_sql
from system_privilege_map S,sys.sysauth$ P,sys.dba_users U
where U.user_id    = P.grantee#
and P.privilege# = S.privilege
and P.privilege# < 0
union
select '/* j */' step,'grant '||X.name||' to '||U.username||';'||chr(10) creation_sql
from sys.user$ X,sys.dba_users U
where X.user#  IN ( select  privilege# from sys.sysauth$ connect by  grantee# = prior privilege#
                    and privilege# > 0 start with grantee# in (1,U.user_id ) and privilege# > 0)
union
select '/* k */' step,'create public synonym '||synonym_name||' for '||decode(table_owner,'','',table_owner||'.')||table_name||
decode(db_link,'','','@'||db_link)||';'||chr(10) creation_sql
from sys.dba_synonyms
where owner = 'PUBLIC'
and table_owner != 'SYS'
union
select '/* l */' step,'create public database link '||db_link||chr(10)||'connect to '||
username||' identified by XXXXXX using '''||host||''';'||chr(10) creation_sql
from sys.dba_db_links
where owner = 'PUBLIC'
union
select '/* m */' step,'create rollback segment '||segment_name||' tablespace '||tablespace_name||chr(10)||
'storage (initial '||to_char(initial_extent)||' next '||to_char(next_extent)||' minextents '||
to_char(min_extents)||chr(10)||' maxextents '||to_char(max_extents)||') '||status||';'||chr(10)||chr(10) creation_sql
from   sys.dba_rollback_segs
where  segment_name != 'SYSTEM'
order by 1
