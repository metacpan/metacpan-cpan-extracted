select b.file_name
,a.segment_name
,sum(a.blocks)
from dba_extents a, dba_data_files b
where a.file_id = b.file_id
and b.file_name = ?
group by b.file_name, a.segment_name
