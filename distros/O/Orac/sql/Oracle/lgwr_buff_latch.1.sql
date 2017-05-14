select name,
sum (gets) MainGets,
sum (misses) MainMisses,
sum (immediate_gets) ImGets,
sum (immediate_misses) ImMisses
from v$latch
where name like '%redo%'
group by name
