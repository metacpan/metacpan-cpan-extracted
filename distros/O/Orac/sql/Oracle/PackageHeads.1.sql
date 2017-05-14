select distinct owner
from   dba_source
where  type = 'PACKAGE'
order by owner
