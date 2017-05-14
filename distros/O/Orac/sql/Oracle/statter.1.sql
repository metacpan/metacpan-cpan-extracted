select Statistic#, Sid, Value
from v$sesstat
where Statistic# = ?
order by Sid
