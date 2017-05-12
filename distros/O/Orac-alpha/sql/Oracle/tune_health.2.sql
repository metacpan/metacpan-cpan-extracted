/* Thanks to Duncan Lawie and his team for providing this */
/* slightly alternative view on Hit Ratios, which you may prefer. */
/* If anybody has any other combinations which they think may be useful */
/* to other users of Orac, please let us have them, and we'll consider */
/* them for general inclusion. */
select 'dc_hit_ratio' ratio, 1 step_order,(sum(gets-getmisses)/sum(gets))*100
from v$rowcache
union
select 'lc_hit_ratio' ratio, 2 step_order, (1-sum(reloads)/sum(pins))*100
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
