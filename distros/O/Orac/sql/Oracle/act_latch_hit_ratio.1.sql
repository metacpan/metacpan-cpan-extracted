select n.name,p.pid,round(((l.misses/l.gets)*100),2) wait_ratio
from v$process p,v$latchname n,v$latch l
where p.latchwait is not null
and p.latchwait = l.addr
and l.latch# = n.latch#
