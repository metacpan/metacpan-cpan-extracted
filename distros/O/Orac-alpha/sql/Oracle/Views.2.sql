select distinct view_name 
from dba_views
where UPPER(owner) = UPPER( ? )
order by view_name
