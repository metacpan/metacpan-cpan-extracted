declare
   cursor c_work_out_tabsp (my_tabsp in varchar2) is
      select file_name,bytes
      from dba_data_files
      where tablespace_name = my_tabsp
      order by file_id;
   cursor c_log_interrogate is
      select group#,members,bytes
      from v$log
      where thread# = 1 order by 1;
   cursor c_thread_curs is
      select thread#,group#,members,bytes
      from v$log
      where thread# > 1 order by 1,2;
   cursor lfile_c (my_group in number) is
      select member
      from v$logfile
      where group# = my_group;
   cursor tbsp_c is
      select ts.name,ts.blocksize * ts.dflinit,ts.blocksize * ts.dflincr,
             ts.dflminext,ts.dflmaxext,ts.dflextpct,
             decode(mod(ts.online$,65536),1,'ONLINE',2,'OFFLINE',4,'READ ONLY','UNDEFINED'),
             decode(floor(ts.online$/65536),0,'PERMANENT',1,'TEMPORARY')
      from sys.ts$ ts
      where ts.name <> 'SYSTEM' and mod(ts.online$,65536) != 3
      order by 1;
   cursor r_c is
      select owner,segment_name,tablespace_name,initial_extent,
             next_extent,min_extents,max_extents,pct_increase
      from dba_rollback_segs
      where segment_name not in ('SYSTEM','R000')
      order by segment_name;
   cursor o_c (my_segment_name in varchar2) is
      select decode(c.optsize,NULL,a.initial_extent * a.min_extents,c.optsize)
      from dba_rollback_segs a,v$rollname b,v$rollstat c
      where my_segment_name not in ('SYSTEM','R000')
      and a.segment_name = my_segment_name and a.segment_name = b.name and b.usn = c.usn;
   cursor c_alt_roll is
      select 'ALTER ROLLBACK SEGMENT '||segment_name||' '||status||';'
      from   dba_rollback_segs
      where  segment_name not in ('SYSTEM','R000')
      and    status = 'ONLINE'
      order by 1;
   l_maxmemlen number;
   v_filename sys.dba_data_files.file_name%TYPE;
   v_bytes number;
   p_thd# sys.v_$log.thread#%TYPE;
   l_thd# sys.v_$log.thread#%TYPE;
   p_grp# sys.v_$log.group#%TYPE;
   l_gp# sys.v_$log.group#%TYPE;
   l_mbs sys.v_$log.members%TYPE;
   l_mr sys.v_$logfile.member%TYPE;
   l_tbsp sys.dba_tablespaces.tablespace_name%TYPE;
   l_iex sys.dba_tablespaces.initial_extent%TYPE;
   l_nexex sys.dba_tablespaces.next_extent%TYPE;
   l_minex sys.dba_tablespaces.min_extents%TYPE;
   l_maxexs sys.dba_tablespaces.max_extents%TYPE;
   l_pctin sys.dba_tablespaces.pct_increase%TYPE;
   l_tbsp_st varchar2(30);
   l_tbsp_cont varchar2(30);
   l_on sys.dba_rollback_segs.owner%TYPE;
   l_segn sys.dba_rollback_segs.segment_name%TYPE;
   l_opt number;
   l_iexs varchar2(16);
   l_nxtex_siz varchar2(16);
   l_ownam varchar2(16);
   l_opt_siz varchar2(10);
   l_ln number := 0;
   l_bsz varchar2(16);
   v_line varchar2(200);
   v_dum varchar2(200);
   n number;
   v_counter number;
   v_ora_sid varchar2(50);
   v_bit varchar2(50);
function orac_print(f_line in varchar2) return varchar2 is
begin
   dbms_output.put_line(f_line);
   return f_line;
end orac_print;
begin
   dbms_output.enable(1000000);
   v_ora_sid := ?;
   v_dum := orac_print('rem  ************************************************');
   v_dum := orac_print('rem  crdb'||v_ora_sid||'.sql');
   v_dum := orac_print('rem  ************************************************');
   select 'rem  Database name        :'||value
   into   v_line
   from v$parameter
   where name = 'db_name';
   v_dum := orac_print(v_line);
   select 'rem  Database created     :'||created
   into   v_line
   from v$database;
   v_dum := orac_print(v_line);
   select 'rem  Database log_mode    :'||log_mode
   into   v_line
   from v$database;
   v_dum := orac_print(v_line);
   select 'rem  Database blocksize   :'||value||' bytes'
   into   v_line
   from v$parameter
   where name = 'db_block_size';
   v_dum := orac_print(v_line);
   select 'rem  Database buffers     :'||value||' blocks'
   into   v_line
   from v$parameter
   where name = 'db_block_buffers';
   v_dum := orac_print(v_line);
   select 'rem  Database log_buffers :'||value||' blocks'
   into   v_line
   from v$parameter
   where name = 'log_buffer';
   v_dum := orac_print(v_line);
   select 'rem  Database ifile       :'||value
   into   v_line
   from v$parameter
   where name = 'ifile';
   v_dum := orac_print(v_line);
   v_dum := orac_print('rem'||chr(10)||
               'rem  Note:  Use ALTER SYSTEM BACKUP CONTROLFILE TO TRACE;');
   v_dum := orac_print('rem  to generate a script to create controlfile');
   v_dum := orac_print('rem  and compare it with the output of this script.');
   v_dum := orac_print('rem  Add MAXLOGFILES, MAXDATAFILES, etc. if reqd.');
   v_dum := orac_print('rem  ************************************************'||chr(10));
   v_dum := orac_print('spool crdb'||v_ora_sid||'.lst');
   v_dum := orac_print('connect internal');
   v_dum := orac_print('startup nomount'||chr(10));
   v_dum := orac_print('rem -- please verify/change the following parameters as needed'||
               chr(10));
   select 'CREATE DATABASE "'||value||'"'
   into   v_line
   from v$parameter
   where name = 'db_name';
   v_dum := orac_print(v_line);
   select '  '||log_mode
   into   v_line
   from v$database;
   v_dum := orac_print(v_line);
   select max(length(member) + 2) maxmem1
   into l_maxmemlen
   from v$logfile;
   v_dum := orac_print(chr(10)||'  REMOVE=>NB: Make sure NOARCHIVELOG/ARCHIVELOG sorted out'||
               chr(10));
   v_dum := orac_print('  /* You may wish to change the following  values,          */');
   v_dum := orac_print('  /* and use values found from a control file backed up     */');
   v_dum := orac_print('  /* to trace.  Alternatively, uncomment these defaults.    */');
   v_dum := orac_print('  /* (MAXLOGFILES and MAXLOGMEMBERS have been selected from   */');
   v_dum := orac_print('  /* v$log, character set from NLS_DATABASE_PARAMETERS.*/'||
               chr(10));
   v_dum := orac_print('  /* option start:use control file*/'||chr(10));
   select '  CHARACTER SET  '||value
   into   v_line
   from nls_database_parameters where parameter = 'NLS_CHARACTERSET';
   v_dum := orac_print(v_line);
   select '  MAXLOGFILES    '||max(group#)*max(members)*4
   into   v_line
   from v$log;
   v_dum := orac_print(v_line);
   select '  MAXLOGMEMBERS  '||max(members) * 2
   into   v_line
   from v$log;
   v_dum := orac_print(v_line);
   v_dum := orac_print('  /* MAXDATAFILES   255 */');
   v_dum := orac_print('  /* MAXINSTANCES   1 */');
   v_dum := orac_print('  /* MAXLOGHISTORY  100 */');
   v_dum := orac_print('  /* option end  :use control file*/'||chr(10));
   v_dum := orac_print('  DATAFILE ');
   v_counter := 0;
   open c_work_out_tabsp('SYSTEM');
   loop
      fetch c_work_out_tabsp into v_filename, v_bytes;
      exit when c_work_out_tabsp%notfound;
      v_counter := v_counter + 1;
      if v_counter != 1 then
         v_bit := '    ,';
      else
         v_bit := '    ';
      end if;
      v_line := (v_bytes/(1024*1024))||'M';
      v_dum := orac_print(v_bit||chr(39)||v_filename||chr(39)||' SIZE '||v_line);
   end loop;
   close c_work_out_tabsp;
   v_dum := orac_print(chr(10)||'  LOGFILE');
   p_grp# := 99999;
   open c_log_interrogate;
   loop
      fetch c_log_interrogate into l_gp#,l_mbs,v_bytes;
      exit when c_log_interrogate%notfound;
      if mod(v_bytes,(1024*1024)) = 0 then
         l_bsz := to_char(v_bytes / (1024*1024))||'M';
      elsif mod(v_bytes,1024) = 0 then
         l_bsz := to_char(v_bytes / 1024)||'K';
      else
         l_bsz := to_char(v_bytes);
      end if;
      if p_grp# != 99999 then
         v_bit := '    ,'||chr(10)||'    ';
      else
         v_bit := '    ';
      end if;
      v_dum := orac_print(v_bit||'GROUP'||to_char(l_gp#,'B99')||' (');
      p_grp# := l_gp#;
      v_counter := 0;
      open lfile_c (l_gp#);
      loop
         fetch lfile_c into l_mr;
         exit when lfile_c%notfound;
         v_counter := v_counter + 1;
         if v_counter = l_mbs then
            v_dum := orac_print('    '||chr(39)||rpad(l_mr||chr(39),l_maxmemlen,' '));
         else
            v_dum := orac_print('    '||chr(39)||rpad(l_mr||chr(39),l_maxmemlen,' ')||',');
         end if;
      end loop;
      close lfile_c;
      v_dum := orac_print('    ) SIZE '||l_bsz);
   end loop;
   close c_log_interrogate;
   v_dum := orac_print(';');
   p_thd# := 99999;
   open c_thread_curs;
   loop
      fetch c_thread_curs into l_thd#,l_gp#,l_mbs,v_bytes;
      exit when c_thread_curs%notfound;
      if p_thd# <> l_thd# then
         p_thd# := l_thd#;
         v_dum := orac_print(' ');
         v_dum := orac_print('ALTER DATABASE ADD LOGFILE THREAD '||to_char(l_thd#));
         p_grp# := 99999;
      end if;
      if mod(v_bytes,(1024*1024)) = 0 then
         l_bsz := to_char(v_bytes / (1024*1024))||'M';
      elsif mod(v_bytes,1024) = 0 then
         l_bsz := to_char(v_bytes / 1024)||'K';
      else
         l_bsz := to_char(v_bytes);
      end if;
      if p_grp# != 99999 then
         v_dum := orac_print(',');
      end if;
      v_dum := orac_print('    GROUP'||to_char(l_gp#,'B99')||' (');
      p_grp# := l_gp#;
      v_counter := 0;
      open lfile_c (l_gp#);
      loop
         fetch lfile_c into l_mr;
         exit when lfile_c%notfound;
         v_counter := v_counter + 1;
         if v_counter != 1 then
            v_dum := orac_print('');
            v_dum := orac_print('    ');
         end if;
         if v_counter = l_mbs then
            v_dum := orac_print(chr(39)||rpad(l_mr||chr(39),l_maxmemlen,' '));
         else
            v_dum := orac_print(chr(39)||rpad(l_mr||chr(39),l_maxmemlen,' ')||',');
         end if;
      end loop;
      close lfile_c;
      v_dum := orac_print(') SIZE '||l_bsz);
   end loop;
   close c_thread_curs;
   v_dum := orac_print(';');
   if p_thd# <> 99999 then
      v_dum := orac_print('rem');
   end if;
   v_dum := orac_print(chr(10)||'rem ----------------------------------------');
   v_dum := orac_print('rem  Need a basic rollback segment before proceeding');
   v_dum := orac_print('rem ----------------------------------------'||chr(10));
   v_dum := orac_print('CREATE ROLLBACK SEGMENT dummy TABLESPACE SYSTEM ');
   v_dum := orac_print('    storage (initial 500K next 500K minextents 2);');
   v_dum := orac_print('ALTER ROLLBACK SEGMENT dummy ONLINE;');
   v_dum := orac_print('commit;');
   v_dum := orac_print('rem ----------------------------------------'||chr(10));
   v_dum := orac_print('rem Create DBA views'||chr(10));
   v_dum := orac_print('@?/rdbms/admin/catalog.sql');
   v_dum := orac_print('commit;');
   v_dum := orac_print(chr(10)||'rem ----------------------------------------');
   v_dum := orac_print('rem  Additional Tablespaces');
   open tbsp_c;
   loop
      fetch tbsp_c into l_tbsp,l_iex,l_nexex,l_minex,l_maxexs, l_pctin,l_tbsp_st,l_tbsp_cont;
      exit when tbsp_c%notfound;
      v_dum := orac_print('rem ----------------------------------------'||chr(10));
      v_dum := orac_print('CREATE TABLESPACE '||l_tbsp||' DATAFILE');
      v_counter := 0;
      open c_work_out_tabsp (l_tbsp);
      loop
         fetch c_work_out_tabsp into v_filename, v_bytes;
         exit when c_work_out_tabsp%notfound;
         v_counter := v_counter + 1;
         if v_counter != 1 then
            v_dum := orac_print(',');
         end if;
         if mod(v_bytes,(1024*1024)) = 0 then
            l_bsz := to_char(v_bytes / (1024*1024))||'M';
         elsif mod(v_bytes,1024) = 0 then
            l_bsz := to_char(v_bytes / 1024)||'K';
         else
            l_bsz := to_char(v_bytes);
         end if;
         v_dum := orac_print('    '||chr(39)||v_filename||chr(39)||' SIZE '||l_bsz);
      end loop;
      close c_work_out_tabsp;
      v_dum := orac_print(' ');
      if mod(l_iex,(1024*1024)) = 0 then
         l_iexs := to_char(l_iex / (1024*1024))||'M';
      elsif mod(l_iex,1024) = 0 then
         l_iexs := to_char(l_iex / 1024)||'K';
      else
         l_iexs := to_char(l_iex);
      end if;
      if mod(l_nexex,(1024*1024)) = 0 then
         l_nxtex_siz := to_char(l_nexex / (1024*1024))||'M';
      elsif mod(l_nexex,1024) = 0 then
         l_nxtex_siz := to_char(l_nexex / 1024)||'K';
      else
         l_nxtex_siz := to_char(l_nexex);
      end if;
      v_dum := orac_print('default storage');
      v_dum := orac_print(' (initial '||l_iexs);
      v_dum := orac_print('  next '||l_nxtex_siz);
      v_dum := orac_print('  pctincrease '||l_pctin);
      v_dum := orac_print('  minextents '||l_minex);
      v_dum := orac_print('  maxextents '||l_maxexs);
      if l_tbsp_cont = 'TEMPORARY' then
         v_dum := orac_print(' ) TEMPORARY ;');
      else
         v_dum := orac_print(' ) ;');
      end if;
      if l_tbsp_st = 'READ ONLY' then
         v_dum := orac_print('ALTER TABLESPACE '||l_tbsp||' READ ONLY ;');
      end if;
   end loop;
   close tbsp_c;
   v_dum := orac_print(chr(10)||'rem ----------------------------------------');
   v_dum := orac_print('rem  Create additional rollback segments'||' in the rollback tablespace');
   v_dum := orac_print('rem ----------------------------------------'||chr(10));
   open r_c;
   loop
      fetch r_c into l_on,l_segn,l_tbsp,l_iex, l_nexex,l_minex,l_maxexs,l_pctin;
      exit when r_c%notfound;
      if l_on = 'PUBLIC' then
         l_ownam := ' PUBLIC ';
      else
         l_ownam := ' ';
      end if;
      if mod(l_iex,(1024*1024)) = 0 then
         l_iexs := to_char(l_iex / (1024*1024))||'M';
      elsif mod(l_iex,1024) = 0 then
         l_iexs := to_char(l_iex / 1024)||'K';
      else
         l_iexs := to_char(l_iex);
      end if;
      if mod(l_nexex,(1024*1024)) = 0 then
         l_nxtex_siz := to_char(l_nexex / (1024*1024))||'M';
      elsif mod(l_nexex,1024) = 0 then
         l_nxtex_siz := to_char(l_nexex / 1024)||'K';
      else
         l_nxtex_siz := to_char(l_nexex);
      end if;
      v_dum := orac_print('CREATE'||l_ownam||'ROLLBACK SEGMENT '||l_segn);
      v_dum := orac_print(' TABLESPACE '||l_tbsp||' STORAGE');
      v_dum := orac_print('    (initial '||l_iexs);
      v_dum := orac_print(' next '||l_nxtex_siz);
      v_dum := orac_print(' minextents '||l_minex);
      v_dum := orac_print(' maxextents '||l_maxexs);
      open o_c (l_segn);
      fetch o_c into l_opt;
      if o_c%found then
         if mod(l_opt,(1024*1024)) = 0 then
            l_opt_siz := to_char(l_opt / (1024*1024))||'M';
         elsif mod(l_opt,1024) = 0 then
            l_opt_siz := to_char(l_opt / 1024)||'K';
         else
            l_opt_siz := to_char(l_opt);
         end if;
         if l_opt != 0 then
            v_dum := orac_print(' optimal '||l_opt_siz);
         end if;
      end if;
      close o_c;
      v_dum := orac_print(');');
   end loop;
close r_c;
open c_alt_roll;
loop
   fetch c_alt_roll into v_line;
   exit when c_alt_roll%notfound;
   v_dum := orac_print(v_line);
end loop;
v_dum := orac_print(chr(10)||'rem  Take the initial rollback segment (dummy) offline'||chr(10));
v_dum := orac_print('ALTER ROLLBACK SEGMENT dummy OFFLINE;'||chr(10));
v_dum := orac_print('rem ----------------------------------------'||chr(10));
select 'ALTER USER SYS TEMPORARY TABLESPACE '||temporary_tablespace||';'
into   v_line
from dba_users where username = 'SYS';
v_dum := orac_print(v_line);
select 'ALTER USER SYSTEM TEMPORARY TABLESPACE '||temporary_tablespace||' DEFAULT TABLESPACE '||
default_tablespace||';'
into   v_line
from dba_users where username = 'SYSTEM';
v_dum := orac_print(v_line||chr(10));
v_dum := orac_print('rem ----------------------------------------'||chr(10));
v_dum := orac_print('rem  Run other @?/rdbms/admin required scripts'||chr(10));
v_dum := orac_print('commit;'||chr(10));
v_dum := orac_print('@?/rdbms/admin/catproc.sql'||chr(10));
v_dum := orac_print('rem You may wish to uncomment the following scripts?');
v_dum := orac_print('rem @?/rdbms/admin/catparr.sql');
v_dum := orac_print('rem @?/rdbms/admin/catexp.sql');
v_dum := orac_print('rem @?/rdbms/admin/catrep.sql');
v_dum := orac_print('rem @?/rdbms/admin/dbmspool.sql');
v_dum := orac_print('rem @?/rdbms/admin/utlmontr.sql'||chr(10));
v_dum := orac_print('commit;'||chr(10));
v_dum := orac_print('connect system/manager');
v_dum := orac_print('@?/sqlplus/admin/pupbld.sql');
v_dum := orac_print('@?/rdbms/admin/catdbsyn.sql'||chr(10));
v_dum := orac_print('commit;'||chr(10));
v_dum := orac_print('spool off');
v_dum := orac_print('exit'||chr(10));
v_dum := orac_print('rem EOF');
end;
