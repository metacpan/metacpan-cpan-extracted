/* Change by Andre Seesink 5th Jan 2000 */
select s.sid || ' ' || s.username
from v$process p,v$session s
where s.paddr(+) = p.addr
order by s.logon_time
