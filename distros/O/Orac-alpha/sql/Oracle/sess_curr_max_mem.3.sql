select SUM(value) "Total Session UGA Max"
from v$sysstat
where name = 'session uga memory max'
