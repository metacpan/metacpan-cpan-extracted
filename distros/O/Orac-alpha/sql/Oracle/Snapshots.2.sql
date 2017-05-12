select name
from   dba_snapshots
where  UPPER(owner) = UPPER( ? )
order by name
