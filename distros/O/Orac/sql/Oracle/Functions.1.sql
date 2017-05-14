select distinct owner
from   dba_source
where  type = 'FUNCTION'
order by owner
