select s.sid
from v$process p,v$session s
where s.paddr(+) = p.addr
order by s.logon_time
