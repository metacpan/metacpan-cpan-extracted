select db_link
from   dba_db_links
where  UPPER(owner) = UPPER( ? )
order by 1
