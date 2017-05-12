select o.name, user_name(o.uid) 
from sysobjects o 
where type ="U" and not exists(
                                select * from sysattributes
                                 where class = 9 and attribute = 1 and
                                       object_cinfo = o.name) 
  and user_name(o.uid) is not NULL
order by name
