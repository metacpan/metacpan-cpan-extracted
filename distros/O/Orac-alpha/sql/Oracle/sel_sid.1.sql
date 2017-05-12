select /*+ use_nl(c,a) */ a.sid "Sid",
a.username "Username",
b.name "Name",
c.value "Value"
from v$session a,v$statname b,v$sesstat c
where a.sid = c.sid and b.statistic# = c.statistic#
and a.sid = ?
and c.value > 0
order by b.name
