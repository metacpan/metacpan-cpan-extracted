/* Copyright 1999 by Kevin L. Kitts                  */
/* This code is released under the terms of the GPL  */
/* Please see the readme for the GNU GPL for details */
select 'Data' Type,
        file_name,
        tablespace_name Tablespace,
        lpad(to_char(bytes/(1024*1024)), 8) "SIZE(MB)",
        status
  from  dba_data_files
union all
select 'Control',
        name,
       '',
       '',
        status
  from  v$controlfile
union all
select 'Redo' || ' (' || 'Group ' || a.group# || ')',
        member,
       '',
        lpad(to_char(bytes/(1024*1024)), 8),
        a.status
  from  v$log a, v$logfile b
 where  a.group# = b.group#
