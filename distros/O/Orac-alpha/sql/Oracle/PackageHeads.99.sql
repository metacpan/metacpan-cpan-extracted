declare
   cursor packh_c is
      select owner,name, rtrim(text, chr(10)) text
      from dba_source
      where type = 'PACKAGE'
      and owner = ?
      and name = ?
      order by owner,name,line;
   packh_r packh_c%ROWTYPE;
   l_start_pos NUMBER;
   l_end_pos NUMBER;
   l_proc_flag NUMBER;
   l_name_flag NUMBER;
   l_numb NUMBER;
   l_upp_text sys.dba_source.text%TYPE;
   l_res_text sys.dba_source.text%TYPE;
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
begin
   dbms_output.enable(1000000);
   l_proc_flag := 0;
   l_name_flag := 0;
   open packh_c;
   loop
      fetch packh_c into packh_r;
      exit when packh_c%notfound;
      if l_proc_flag = 0 then
         l_upp_text := upper(packh_r.text);
         l_start_pos := instr(l_upp_text, 'PACKAGE');
         if l_start_pos != 0 then
            l_end_pos := l_start_pos + length('PACKAGE');
            l_res_text := substr(packh_r.text, 1, (l_start_pos - 1)) ||
                          'CREATE OR REPLACE PACKAGE' ||
                          substr(packh_r.text, l_end_pos);
            packh_r.text := l_res_text;
            l_proc_flag := 1;
         end if;
      end if;
      if l_name_flag = 0 then
         l_upp_text := upper(packh_r.text);
         l_start_pos := instr(l_upp_text, packh_r.name);
         if l_start_pos != 0 then
            l_end_pos := l_start_pos + length(packh_r.name);
            l_res_text := substr(packh_r.text, 1, (l_start_pos - 1)) ||
                          packh_r.owner||'.'||packh_r.name ||
                          substr(packh_r.text, l_end_pos);
            packh_r.text := l_res_text;
            l_name_flag := 1;
         end if;
      end if;
      l_numb := orac_write(packh_r.text);
   end loop;
   close packh_c;
end;
