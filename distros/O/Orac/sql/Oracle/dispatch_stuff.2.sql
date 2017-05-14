select Network,
decode(totalq,0,'NO RESPONSES',wait/totalq||' 100THS SECS') "Average_Wait"
from v$queue Q, v$dispatcher D
where UPPER(Q.type) = 'DISPATCHER'
and Q.paddr = D.paddr
