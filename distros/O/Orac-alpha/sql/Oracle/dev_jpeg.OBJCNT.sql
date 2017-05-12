select object_type
,count(*)
from user_objects
group by object_type
