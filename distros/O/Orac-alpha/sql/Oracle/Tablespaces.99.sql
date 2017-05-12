declare
   cursor dataf_c (c_tabsp in varchar2) is
      select file_name,
             bytes
      from dba_data_files
      where tablespace_name = c_tabsp
      order by file_id;
   --
   dataf_r dataf_c%ROWTYPE;
   --
   cursor tbsp_c (c_tablespace in varchar2) is
      select ts.name tablespace_name,
             ts.blocksize * ts.dflinit initial_extent,
             ts.blocksize * ts.dflincr next_extent,
             ts.dflminext min_extent,
             ts.dflmaxext max_extent,
             ts.dflextpct pct_increase,
             decode(mod(ts.online$,65536),
                    1,'ONLINE',
                    2,'OFFLINE',
                    4,'READ ONLY',
                    'UNDEFINED') tablespace_status,
             decode(floor(ts.online$/65536),
                    0,'PERMANENT',
                    1,'TEMPORARY') tablespace_type
      from sys.ts$ ts
      where ts.name = c_tablespace
      and   mod(ts.online$,65536) != 3
      order by 1;
   --
   tbsp_r tbsp_c%ROWTYPE;
   --
   l_iexs varchar2(30);
   l_nxtex_siz varchar2(30);
   l_bsz varchar2(30);
   v_dum varchar2(200);
   v_counter number;
   --
   l_tablespace sys.dba_tablespaces.tablespace_name%TYPE;
   l_dummy varchar2(30);
   --
function orac_print(f_line in varchar2) return varchar2 is
begin
   dbms_output.put_line(f_line);
   return f_line;
end orac_print;
begin
   l_tablespace := ? ;
   l_dummy := ? ;
   --
   dbms_output.enable(1000000);
   open tbsp_c (l_tablespace);
   loop
      fetch tbsp_c into tbsp_r;
      exit when tbsp_c%notfound;
      v_dum := orac_print('CREATE TABLESPACE ' ||
                          tbsp_r.tablespace_name ||
                          chr(10) ||
                          'DATAFILE');
      v_counter := 0;
      open dataf_c (tbsp_r.tablespace_name);
      loop
         fetch dataf_c into dataf_r;
         exit when dataf_c%notfound;
         v_counter := v_counter + 1;
         if v_counter != 1 then
            v_dum := orac_print(',');
         end if;
         if mod(dataf_r.bytes,(1024*1024)) = 0 then
            l_bsz := to_char(dataf_r.bytes / (1024*1024))||'M';
         elsif mod(dataf_r.bytes,1024) = 0 then
            l_bsz := to_char(dataf_r.bytes / 1024)||'K';
         else
            l_bsz := to_char(dataf_r.bytes);
         end if;
         v_dum := orac_print('    '||
                             chr(39)||
                             dataf_r.file_name||
                             chr(39)||
                             ' SIZE '||l_bsz);
      end loop;
      close dataf_c;
      if mod(tbsp_r.initial_extent,(1024*1024)) = 0 then
         l_iexs := to_char(tbsp_r.initial_extent / (1024*1024))||'M';
      elsif mod(tbsp_r.initial_extent,1024) = 0 then
         l_iexs := to_char(tbsp_r.initial_extent / 1024)||'K';
      else
         l_iexs := to_char(tbsp_r.initial_extent);
      end if;
      if mod(tbsp_r.next_extent,(1024*1024)) = 0 then
         l_nxtex_siz := to_char(tbsp_r.next_extent / (1024*1024))||'M';
      elsif mod(tbsp_r.next_extent,1024) = 0 then
         l_nxtex_siz := to_char(tbsp_r.next_extent / 1024)||'K';
      else
         l_nxtex_siz := to_char(tbsp_r.next_extent);
      end if;
      v_dum := orac_print('default storage');
      v_dum := orac_print(' (initial '||l_iexs);
      v_dum := orac_print('  next '||l_nxtex_siz);
      v_dum := orac_print('  pctincrease '||tbsp_r.pct_increase);
      v_dum := orac_print('  minextents '||tbsp_r.min_extent);
      v_dum := orac_print('  maxextents '||
                          tbsp_r.max_extent);
      if tbsp_r.tablespace_type = 'TEMPORARY' then
         v_dum := orac_print(' ) TEMPORARY ;');
      else
         v_dum := orac_print(' ) ;');
      end if;
      if tbsp_r.tablespace_status = 'READ ONLY' then
         v_dum := orac_print('ALTER TABLESPACE '||
                             tbsp_r.tablespace_name||
                             ' READ ONLY ;');
      end if;
   end loop;
   close tbsp_c;
end;
