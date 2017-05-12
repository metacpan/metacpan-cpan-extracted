select object_type
,count(*)
from user_objects
where status = 'INVALID'
group by object_type
