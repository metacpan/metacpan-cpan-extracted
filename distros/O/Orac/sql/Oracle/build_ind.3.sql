select pct_free,ini_trans
from dba_tables
where owner = upper( ? )
and table_name = upper( ? )
