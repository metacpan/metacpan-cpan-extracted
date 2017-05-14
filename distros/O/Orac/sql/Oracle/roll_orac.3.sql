select name "Rollback Segment", 
tablespace_name "Tablespace", 
r.status "Current Status"
from v$rollstat r,v$rollname n,dba_rollback_segs
where r.usn = n.usn and 
name = segment_name
