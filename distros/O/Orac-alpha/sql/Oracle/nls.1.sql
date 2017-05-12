select 'Database' nls_type, PARAMETER,VALUE
from NLS_DATABASE_PARAMETERS
union
select  'Inst' nls_type, parameter,value
from NLS_INSTANCE_PARAMETERS
union
select  'Session' nls_type, PARAMETER,VALUE
from NLS_SESSION_PARAMETERS
order by 1, 2
