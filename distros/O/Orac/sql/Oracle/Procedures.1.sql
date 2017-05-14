select distinct owner
from   dba_source
where  type = 'PROCEDURE'
order by owner
