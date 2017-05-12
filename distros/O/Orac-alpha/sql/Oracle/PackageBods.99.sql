declare
   cursor packb_c is
      select owner,name, rtrim(text, chr(10)) text
      from dba_source
      where type = 'PACKAGE BODY'
      and owner = ?
      and name = ?
      order by owner,name,line;
   packb_r packb_c%ROWTYPE;
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
   open packb_c;
   loop
      fetch packb_c into packb_r;
      exit when packb_c%notfound;
      if l_proc_flag = 0 then
         l_upp_text := upper(packb_r.text);
         l_start_pos := instr(l_upp_text, 'PACKAGE BODY');
         if l_start_pos != 0 then
            l_end_pos := l_start_pos + length('PACKAGE BODY');
            l_res_text := substr(packb_r.text, 1, (l_start_pos - 1)) ||
                          'CREATE OR REPLACE PACKAGE BODY' ||
                          substr(packb_r.text, l_end_pos);
            packb_r.text := l_res_text;
            l_proc_flag := 1;
         end if;
      end if;
      if l_name_flag = 0 then
         l_upp_text := upper(packb_r.text);
         l_start_pos := instr(l_upp_text, packb_r.name);
         if l_start_pos != 0 then
            l_end_pos := l_start_pos + length(packb_r.name);
            l_res_text := substr(packb_r.text, 1, (l_start_pos - 1)) ||
                          packb_r.owner||'.'||packb_r.name ||
                          substr(packb_r.text, l_end_pos);
            packb_r.text := l_res_text;
            l_name_flag := 1;
         end if;
      end if;
      l_numb := orac_write(packb_r.text);
   end loop;
   close packb_c;
end;
