select object_type
,count(*)
from dba_objects
group by object_type
