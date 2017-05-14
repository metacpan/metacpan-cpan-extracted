select master
from   dba_snapshot_logs
where  UPPER(log_owner) = UPPER( ? )
order by master
