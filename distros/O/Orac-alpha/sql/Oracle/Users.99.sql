declare
   cursor user_c (c_gen_owner varchar2) is
      select username,password,
             default_tablespace,temporary_tablespace,
             profile
      from dba_users
      where username = c_gen_owner
      order by username;
   user_r user_c%ROWTYPE;
   --
   cursor quota_c (l_in_user varchar2) is
      select tablespace_name, max_bytes
      from dba_ts_quotas
      where username = l_in_user;
   quota_r quota_c%ROWTYPE;
   --
   l_gen_owner sys.dba_tables.owner%TYPE;
   l_gen_table sys.dba_tables.table_name%TYPE;
   --
   l_return number;
   --
function orac_quota(l_inner in number) return varchar2 is
begin
   if l_inner = -1 then
      return 'UNLIMITED';
   elsif mod(l_inner,(1024 * 1024)) = 0 then
      return to_char(l_inner / (1024 * 1024))||'M';
   elsif mod(l_inner,1024) = 0 then
      return to_char(l_inner / 1024)||'K';
   else
      return to_char(l_inner);
   end if;
end orac_quota;
--
function orac_write(l_in_text in VARCHAR2) return number is
    l_counter number;
    l_text VARCHAR2(500);
    l_keep_text VARCHAR2(500);
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
   l_gen_owner := ?;
   l_gen_table := ?;
   --
   open user_c(l_gen_owner);
   loop
      fetch user_c into user_r;
      exit when user_c%NOTFOUND;
      --
      l_return := orac_write('CREATE USER ' ||
                             user_r.username ||
                             ' IDENTIFIED BY VALUES ' ||
                             chr(39) ||
                             user_r.password ||
                             chr(39));
      l_return := orac_write('  DEFAULT TABLESPACE ' ||
                             user_r.default_tablespace);
      l_return := orac_write('  TEMPORARY TABLESPACE ' ||
                             user_r.temporary_tablespace);
      --
      open quota_c( user_r.username );
      loop
         fetch quota_c into quota_r;
         exit when quota_c%NOTFOUND;
         --
         l_return := orac_write('  QUOTA ' ||
                                orac_quota(quota_r.max_bytes) ||
                                ' ON ' ||
                                quota_r.tablespace_name);
      end loop;
      close quota_c;
      l_return := orac_write('  PROFILE ' ||
                             user_r.profile ||
                             ';' );
   end loop;
   close user_c;
end;
