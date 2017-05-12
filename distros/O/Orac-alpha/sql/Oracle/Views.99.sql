declare
   cursor view_cursor is
      select owner,view_name,text
      from dba_views
      where owner like ?
      and view_name like ?
      order by owner,view_name;
   l_owner sys.dba_views.owner%TYPE;
   l_view_name sys.dba_views.view_name%TYPE;
   l_text sys.dba_views.text%TYPE;
   l_keep_text sys.dba_views.text%TYPE;
   l_counter number;
begin
   dbms_output.enable(1000000);
   open view_cursor;
   loop
      fetch view_cursor into l_owner, l_view_name, l_text;
      exit when view_cursor%NOTFOUND;
      dbms_output.put_line('create or replace view '||l_owner||'.'||l_view_name||chr(10)||'as');
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
      dbms_output.put_line(';');
   end loop;
   close view_cursor;
end;
