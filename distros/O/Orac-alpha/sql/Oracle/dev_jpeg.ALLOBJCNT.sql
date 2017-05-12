select object_type
,count(*)
from all_objects
group by object_type
