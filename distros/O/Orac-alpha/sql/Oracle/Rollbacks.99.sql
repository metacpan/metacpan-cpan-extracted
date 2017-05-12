declare
   cursor roll_c (c_segment in varchar2) is
      select owner,
             segment_name,
             tablespace_name,
             initial_extent,
             next_extent,
             min_extents,
             max_extents,
             pct_increase
      from dba_rollback_segs
      where segment_name = c_segment
      order by segment_name;
   --
   roll_r roll_c%ROWTYPE;
   --
   cursor opt_c (c_segment_name in varchar2) is
      select decode(c.optsize,
                    NULL,a.initial_extent * a.min_extents,
                    c.optsize) optimal_size
      from dba_rollback_segs a,
           v$rollname b,
           v$rollstat c
      where a.segment_name = c_segment_name
      and   a.segment_name = b.name
      and   b.usn = c.usn;
   --
   opt_r opt_c%ROWTYPE;
   --
   l_iexs varchar2(16);
   l_nxtex_siz varchar2(16);
   l_ownam varchar2(16);
   l_opt_siz varchar2(10);
   v_dum varchar2(200);
   --
   l_segment sys.dba_rollback_segs.segment_name%TYPE;
   l_dummy varchar2(30);
   --
function orac_print(f_line in varchar2) return varchar2 is
begin
   dbms_output.put_line(f_line);
   return f_line;
end orac_print;
begin
   l_segment := ? ;
   l_dummy := ? ;
   --
   dbms_output.enable(1000000);
   open roll_c (l_segment);
   loop
      fetch roll_c into roll_r;
      exit when roll_c%notfound;
      if roll_r.owner = 'PUBLIC' then
         l_ownam := ' PUBLIC ';
      else
         l_ownam := ' ';
      end if;
      if mod(roll_r.initial_extent,(1024*1024)) = 0 then
         l_iexs := to_char(roll_r.initial_extent / (1024*1024))||'M';
      elsif mod(roll_r.initial_extent,1024) = 0 then
         l_iexs := to_char(roll_r.initial_extent / 1024)||'K';
      else
         l_iexs := to_char(roll_r.initial_extent);
      end if;
      if mod(roll_r.next_extent,(1024*1024)) = 0 then
         l_nxtex_siz := to_char(roll_r.next_extent / (1024*1024))||'M';
      elsif mod(roll_r.next_extent,1024) = 0 then
         l_nxtex_siz := to_char(roll_r.next_extent / 1024)||'K';
      else
         l_nxtex_siz := to_char(roll_r.next_extent);
      end if;
      v_dum := orac_print('CREATE'||l_ownam||'ROLLBACK SEGMENT '||roll_r.segment_name);
      v_dum := orac_print('TABLESPACE '||roll_r.tablespace_name||
                          chr(10)||'storage' );
      v_dum := orac_print('(initial '||l_iexs);
      v_dum := orac_print(' next '||l_nxtex_siz);
      v_dum := orac_print(' minextents '||roll_r.min_extents);
      v_dum := orac_print(' maxextents '||roll_r.max_extents);
      open opt_c (roll_r.segment_name);
      fetch opt_c into opt_r;
      if opt_c%found then
         if mod(opt_r.optimal_size,(1024*1024)) = 0 then
            l_opt_siz := to_char(opt_r.optimal_size / (1024*1024))||'M';
         elsif mod(opt_r.optimal_size,1024) = 0 then
            l_opt_siz := to_char(opt_r.optimal_size / 1024)||'K';
         else
            l_opt_siz := to_char(opt_r.optimal_size);
         end if;
         if opt_r.optimal_size != 0 then
            v_dum := orac_print(' optimal '||l_opt_siz);
         end if;
      end if;
      close opt_c;
      v_dum := orac_print(');');
   end loop;
close roll_c;
end;
