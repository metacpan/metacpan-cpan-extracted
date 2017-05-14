select SUM(value) "Total Session UGA"
from v$sysstat
where name = 'session uga memory'
