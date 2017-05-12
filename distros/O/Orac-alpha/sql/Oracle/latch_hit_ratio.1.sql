select n.name,h.pid,round(((l.misses/l.gets)*100),2) wait_ratio
from v$latchholder h,v$latchname n,v$latch l
where h.laddr = l.addr
and l.latch# = n.latch#
