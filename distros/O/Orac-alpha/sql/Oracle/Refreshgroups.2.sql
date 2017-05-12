select rname
from   dba_refresh
where  UPPER(rowner) = UPPER( ? )
order by rname
