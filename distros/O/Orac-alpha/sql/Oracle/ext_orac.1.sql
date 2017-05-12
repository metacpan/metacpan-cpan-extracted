select owner "Owner",
tablespace_name "Tablespace Name",
segment_type "Type",
segment_name "Segment Name",
decode(max_extents,'2147483645','ULTD',to_char(round(max_extents,2))) "Maxt", 
extents "Exts",
round((extents/max_extents*100),2) "Pct",
decode(sign(75 - (extents/max_extents*100)),-1,' * ',decode(sign(20 - extents) ,-1,' * ','')) "Fix"
from dba_segments
where extents > 1
and segment_type != 'ROLLBACK'
and segment_type != 'CACHE'
and owner != 'SYS'
order by 8,7 desc,6 desc,1,4
