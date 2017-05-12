select d.tablespace_name "Tablespace",
d.file_id "File ID",
d.bytes/1024/1024 "Total MB",
d.bytes/ ? "Oracle Blocks",
nvl(sum(e.blocks),0.00) "Tot Used",
nvl(round(((sum(e.blocks)/
(d.bytes/ ? ))*100),2),0.00) "Pct Used"
from dba_extents e,dba_data_files d
where d.file_id = e.file_id (+)
group by d.tablespace_name,D.file_id,d.bytes
