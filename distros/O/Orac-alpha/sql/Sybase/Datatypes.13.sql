select distinct name 
from systypes
where type < 100
  and name not in ('sysname', 'nvarchar', 'nchar', 'intn')
 order by 1

