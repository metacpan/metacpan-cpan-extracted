declare
--
   cursor cm_c (c_gen_owner varchar2, c_gen_table varchar2) is
      select owner,
             table_name,
             table_type,
             comments
      from dba_tab_comments
      where owner = c_gen_owner
      and table_name = c_gen_table
      and comments is not null
      order by owner,table_name;
   cm_r cm_c%ROWTYPE;
--
   cursor com_c (c_gen_owner varchar2, c_gen_table varchar2) is
      select owner,
             table_name,
             column_name,
             comments 
      from dba_col_comments
      where owner = c_gen_owner
      and table_name = c_gen_table
      and comments is not null
      order by owner,table_name,column_name;
   com_r com_c%ROWTYPE;
--
l_gen_owner sys.dba_tables.owner%TYPE;
l_gen_table sys.dba_tables.table_name%TYPE;
--
l_dummy number;
--
function orac_write(l_in_text in sys.dba_source.text%TYPE) return number is
    l_counter number;
    l_text sys.dba_source.text%TYPE;
    l_keep_text sys.dba_source.text%TYPE;
begin
   l_text := l_in_text;
   while length(l_text) > 250
   loop
      l_counter := instr(l_text, chr(10));
      if l_counter > 0 then
         l_keep_text := substr(l_text,0,(instr(l_text, chr(10)) - 1));
         if length(l_keep_text) < 250 then
            dbms_output.put_line(l_keep_text);
            l_text := substr(l_text,(instr(l_text, chr(10)) + 1));
         else
            l_keep_text := substr(l_text,0,250);
            dbms_output.put_line(l_keep_text);
            l_text := substr(l_text,(250 + 1));
         end if;
      else
         l_keep_text := substr(l_text,0,250);
         dbms_output.put_line(l_keep_text);
         l_text := substr(l_text,(250 + 1));
      end if;
   end loop;
   dbms_output.put_line(l_text);
   return 1;
end orac_write;
--
begin
   l_gen_owner := ? ;
   l_gen_table := ? ;
   open cm_c(l_gen_owner, l_gen_table);
   loop
      fetch cm_c into cm_r;
      exit when cm_c%NOTFOUND;
      --
      l_dummy := orac_write('COMMENT ON TABLE ' ||
                            cm_r.owner || '.' || cm_r.table_name || ' IS');
      l_dummy := orac_write(chr(39) || cm_r.comments || chr(39) || ' ;');
      --
   end loop;
   close cm_c;
   --
   open com_c(l_gen_owner, l_gen_table);
   loop
      fetch com_c into com_r;
      exit when com_c%NOTFOUND;
      --
      l_dummy := orac_write( 'COMMENT ON COLUMN ' ||
                             com_r.owner ||'.'||com_r.table_name || 
                             '.' || com_r.column_name || ' IS');
      l_dummy := orac_write( chr(39) || com_r.comments || chr(39) || ' ;');
      --
   end loop;
   close com_c;
   --
end;
