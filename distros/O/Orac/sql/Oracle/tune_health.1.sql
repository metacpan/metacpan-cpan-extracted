select 'dc_hit_ratio' ratio, 1 step_order,(sum(getmisses)/sum(gets))*100
from v$rowcache
union
select 'lc_hit_ratio' ratio, 2 step_order, (sum(reloads)/sum(pins))*100
from v$librarycache
union
select 'bc_hit_ratio' ratio, 3 step_order,( sum(decode(name, 'consistent gets',value,0))
+ sum(decode(name,'db block gets', value,0))
- sum(decode(name,'physical reads', value,0)))
/ ( sum(decode(name, 'consistent gets',value,0))
  + sum(decode(name,'db block gets', value,0)) ) * 100
from v$sysstat
union
select 'roll_ratio' ratio, 4 step_order, round((sum(waits) / (sum(gets) + .00000001)) * 100,2)
from v$rollstat
union
select 'w2wait_ratio' ratio, 5 step_order, (l.misses/l.gets)*100
from v$latch l,v$latchname n
where n.name in ('redo allocation')
and n.latch# = l.latch#
order by 2
