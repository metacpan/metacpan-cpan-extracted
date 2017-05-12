select object_type
,count(*)
from dba_objects
where status = 'INVALID'
group by object_type
