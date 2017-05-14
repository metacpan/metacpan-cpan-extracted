select
decode(totalq,0,'NO REQUESTS',wait/totalq||' 100THS SECS') "Average_Wait"
from v$queue
where upper(type) = 'COMMON'
