select distinct name
from   dba_source
where  UPPER(owner) = UPPER( ? )
and    type = 'FUNCTION'
order by name
