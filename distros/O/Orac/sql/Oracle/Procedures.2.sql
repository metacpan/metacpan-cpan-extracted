select distinct name
from   dba_source
where  UPPER(owner) = UPPER( ? )
and    type = 'PROCEDURE'
order by name
