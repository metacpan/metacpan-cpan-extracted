select object_type
,count(*)
from all_objects
where status = 'INVALID'
group by object_type
