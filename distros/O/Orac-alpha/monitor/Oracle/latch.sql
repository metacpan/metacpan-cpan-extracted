/* Finds the Willing to Wait Ratio (w2w) */
/* Any value less than 99 is red, 99.5, yellow */
select round((100 - ((l.misses/(l.gets + .00000001))*100)),2) w2wait_ratio
from v$latch l, v$latchname n
where n.name in ('redo copy', 'redo allocation')
and n.latch# = l.latch#
