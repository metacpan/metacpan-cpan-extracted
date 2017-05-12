/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */
/* INIT and MAXTRANS change by Tom Lowery 22-10-1999 */

declare
   cursor ctc is
      select upper(owner) capown,upper(table_name) captab,pct_free,pct_used,
             nvl(ini_trans,1) initrans,nvl(max_trans,1) maxtrans,
             tablespace_name,initial_extent,next_extent,min_extents,
             max_extents,freelists,freelist_groups,pct_increase
      from dba_tables
      where owner = ?
      and table_name = ?
      order by owner,table_name;
   ctr ctc%ROWTYPE;
   cursor csc (s_own VARCHAR2,s_tab VARCHAR2) is
      select bytes
      from dba_segments
      where segment_name = s_tab and
            owner = s_own and
            segment_type = 'TABLE';
   csr csc%ROWTYPE;
   cursor ccc (c_own VARCHAR2,c_tab VARCHAR2) is
      select upper(column_name) colname,upper(data_type) datatype,
             data_length,data_precision,data_scale,
             nullable,default_length,data_default,column_id
      from dba_tab_columns
      where table_name = c_tab and
            owner = c_own
      order by column_id;
   ccr ccc%ROWTYPE;
function orac_1024(l_in in number) return varchar2 is
begin
   if mod(l_in,(1024*1024)) = 0 then
      return to_char(l_in / (1024*1024))||'M';
   elsif mod(ctr.initial_extent,1024) = 0 then
      return to_char(l_in / 1024)||'K';
   else
      return to_char(l_in);
   end if;
end orac_1024;
begin
   dbms_output.enable(1000000);
   open ctc;
   loop
      fetch ctc into ctr;
      exit when ctc%notfound;
      dbms_output.put_line('create table '||ctr.capown||'.'||ctr.captab||' (');
      open ccc(ctr.capown,ctr.captab);
      loop
         fetch ccc into ccr;
         exit when ccc%notfound;
         if ccr.column_id <> 1 then
            dbms_output.put_line(',');
         end if;
         dbms_output.put(rpad((upper(ccr.colname)),40));
         dbms_output.put(' '||upper(ccr.datatype));
         if ccr.datatype = 'CHAR' or
            ccr.datatype = 'VARCHAR2' or
            ccr.datatype = 'RAW' then
            dbms_output.put('('||ccr.data_length||')');
         end if;
         if (ccr.datatype = 'NUMBER'
            and nvl(ccr.data_precision,0) != 0) or ccr.datatype = 'FLOAT' then
            if nvl(ccr.data_scale,0) = 0 then
               dbms_output.put('('||ccr.data_precision||')');
            else
               dbms_output.put('('||ccr.data_precision||','||
                                ccr.data_scale||')');
            end if;
         end if;
         if ccr.default_length != 0 then
            dbms_output.put_line(' default '||ccr.data_default);
         end if;
         if ccr.nullable = 'N' then
            dbms_output.put(' NOT NULL');
         end if;
      end loop;
      close ccc;
      dbms_output.put_line(')'||chr(10));
      dbms_output.put_line(' PCTFREE    '||to_char(ctr.pct_free));
      dbms_output.put_line(' PCTUSED    '||to_char(ctr.pct_used));
      dbms_output.put_line(' INITRANS   '||to_char(ctr.initrans));
      dbms_output.put_line(' MAXTRANS   '||to_char(ctr.maxtrans));
      dbms_output.put_line(' TABLESPACE '||ctr.tablespace_name);
      dbms_output.put_line(chr(10)||'STORAGE (');
      dbms_output.put_line('INITIAL         '||orac_1024(ctr.initial_extent));
      dbms_output.put_line('NEXT            '||orac_1024(ctr.next_extent));
      dbms_output.put_line('MINEXTENTS      '||to_char(ctr.min_extents));
      dbms_output.put_line('MAXEXTENTS      '||to_char(ctr.max_extents));
      dbms_output.put_line('PCTINCREASE     '||to_char(ctr.pct_increase));
      dbms_output.put_line('FREELISTS       '||to_char(ctr.freelists));
      dbms_output.put_line('FREELIST GROUPS '||to_char(ctr.freelist_groups));
      dbms_output.put_line(');');
   end loop;
   close ctc;
end;
