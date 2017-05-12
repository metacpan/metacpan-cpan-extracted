/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */

declare
cursor dba_indexes_csr
    (cp_owner varchar2,cp_index varchar2) is
    select *
      from dba_indexes
     where table_owner=cp_owner
       and index_name=cp_index
      order by uniqueness desc , index_name;
 cursor dba_tab_ind_cols_csr
    (cp_owner varchar2,cp_table varchar2,cp_index varchar2) is
    select *
      from dba_ind_columns
     where table_owner=cp_owner
       and table_name=cp_table
       and index_name=cp_index
      order by column_position;
 l_owner varchar2(255);
 l_index varchar2(255);
 l_dummy number;
 l_counter number;
 l_comma_bit varchar2(10);
 l_initial varchar2(50);
 l_next varchar2(50);
 l_index_line varchar2(50);
function orac_write(l_in_text in sys.dba_views.text%TYPE) return number is
 l_counter number;
 l_text sys.dba_views.text%TYPE;
 l_keep_text sys.dba_views.text%TYPE;
begin
   l_text := l_in_text;
   while length(l_text) > 80
   loop
      l_counter := instr(l_text, chr(10));
      if l_counter > 0 then
         l_keep_text := substr(l_text,0,(instr(l_text, chr(10)) - 1));
         if length(l_keep_text) < 80 then
            dbms_output.put_line(l_keep_text);
            l_text := substr(l_text,(instr(l_text, chr(10)) + 1));
         else
            l_keep_text := substr(l_text,0,80);
            dbms_output.put_line(l_keep_text);
            l_text := substr(l_text,(80 + 1));
         end if;
      else
         l_keep_text := substr(l_text,0,80);
         dbms_output.put_line(l_keep_text);
         l_text := substr(l_text,(80 + 1));
      end if;
   end loop;
   dbms_output.put_line(l_text);
   return 1;
end orac_write;
function orac_chop(l_inner in number) return varchar2 is
begin
   if mod(l_inner,(1024 * 1024)) = 0 then
      return to_char(l_inner / (1024 * 1024))||'M';
   elsif mod(l_inner,1024) = 0 then
      return to_char(l_inner / 1024)||'K';
   else
      return to_char(l_inner);
   end if;
end orac_chop;
begin
   l_owner := ?;
   l_index := ?;
   l_dummy := orac_write('/* Index '||l_owner||'.'||
                         l_index||' */');
   for index_row in dba_indexes_csr (l_owner,l_index) loop
      if ((index_row.uniqueness = 'UNIQUE') or
          (index_row.uniqueness = 'BITMAP')) then
          l_index_line := ' '||index_row.uniqueness||' ';
      else
          l_index_line := ' ';
      end if;
    
      l_dummy := orac_write(chr(10)||'create'||l_index_line||
                            'index '||
                            l_owner||'.'||index_row.index_name||' on'||
                            chr(10)||l_owner||'.'||index_row.table_name||' (');
      l_counter:=0;
      for ind_col_row in dba_tab_ind_cols_csr(l_owner,index_row.table_name, 
                                              index_row.index_name) loop
         if (l_counter = 0) then
            l_comma_bit := ' ';
         else
            l_comma_bit := ',';
         end if;
         l_counter := l_counter + 1;
         l_dummy := orac_write(l_comma_bit||ind_col_row.column_name);
      end loop;
      l_dummy := orac_write(')');
      l_dummy := orac_write('tablespace '||index_row.tablespace_name);
      l_dummy := orac_write('initrans   '||to_char(index_row.ini_trans));
      l_dummy := orac_write('maxtrans   '||to_char(index_row.max_trans));
      l_dummy := orac_write('pctfree    '||to_char(index_row.pct_free));
      l_initial := orac_chop(index_row.initial_extent);
      l_next := orac_chop(index_row.next_extent);
      l_dummy := orac_write(chr(10)||
                            'storage (');
      l_dummy := orac_write('initial         '||l_initial);
      l_dummy := orac_write('next            '||l_next);
      l_dummy := orac_write('minextents      '||to_char(index_row.min_extents));
      l_dummy := orac_write('maxextents      '||to_char(index_row.max_extents));
      l_dummy := orac_write('pctincrease     '||
                                           to_char(index_row.pct_increase));
      l_dummy := orac_write('freelists       '||to_char(index_row.freelists));
      l_dummy := orac_write('freelist groups '||
                                            to_char(index_row.freelist_groups));
      l_dummy := orac_write(');');
   end loop;
end;
