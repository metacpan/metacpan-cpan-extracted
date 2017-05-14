declare
   cursor role_c (c_gen_owner varchar2) is
      select 'CREATE ROLE '||
             name ||
             ' '||
             decode(password, null, 'NOT IDENTIFIED',
             'EXTERNAL', 'IDENTIFIED EXTERNALLY',
             'GLOBAL', 'IDENTIFIED GLOBALLY',
             'IDENTIFIED BY VALUES '''||password||'''') ||
             ';' orac_string
      from sys.user$
      where type# = 0
      and name LIKE c_gen_owner
      and name not in ('PUBLIC', '_NEXT_USER');
   role_r role_c%ROWTYPE;
   --
   l_gen_owner sys.dba_tables.owner%TYPE;
   l_gen_table sys.dba_tables.table_name%TYPE;
   --
begin
   l_gen_owner := ? ;
   l_gen_table := ? ;
   --
   open role_c (l_gen_owner);
   loop
      fetch role_c into role_r;
      exit when role_c%NOTFOUND;
      dbms_output.put_line( role_r.orac_string );
   end loop;
   close role_c;
end;
