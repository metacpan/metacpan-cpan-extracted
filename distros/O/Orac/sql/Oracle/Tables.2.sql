select table_name
from   dba_tables
where  UPPER(owner) = UPPER( ? )
order by 1
