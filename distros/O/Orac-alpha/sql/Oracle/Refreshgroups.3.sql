select name
from   dba_refresh_children
where  UPPER(rowner) = UPPER( ? )
and    UPPER(rname) = UPPER( ? )
order by name
