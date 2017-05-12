select distinct constraint_name
from   dba_constraints
where  UPPER(owner) = UPPER( ? )
order by 1
