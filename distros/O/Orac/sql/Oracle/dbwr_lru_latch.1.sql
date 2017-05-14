select name,gets,
misses,sleeps,
immediate_gets imm_gets,immediate_misses imm_misses
from v$latch
where name like '%cache buffer%' or
name like '%cache protect%'
order by name
