select decode(x.online$,1,x.name,substr(rpad(x.name,14),1,14)||' OFF') tbsp_nam,
replace(replace (A.file_name,'/databases/',''),'.dbf','') filename,
round((f.blocks * ? )/(1024*1024),2) bytes,
round(sum(s.length * ? )/(1024*1024),2) used,
round(((f.blocks * ? )/(1024*1024)) - nvl(sum (s.length * ? )/(1024*1024),0),2) free,
round(sum(s.length * ?)/(1024*1024)/((f.blocks * ? )/(1024*1024)) * 100,2) pct_used
from sys.dba_data_files A,sys.uet$ s,sys.file$ f,sys.ts$ X
where x.ts# = f.ts#
and x.online$ in (1,2)
and f.status$ = 2
and f.ts# = s.ts# (+)
and f.file# = s.file# (+)
and f.file# = a.file_id
group by x.name,x.online$,f.blocks,A.file_name
order by tbsp_nam,filename
