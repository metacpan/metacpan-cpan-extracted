select /*+ ORDERED */
s.sid "Sid",s.osuser "OS User",s.username "Username",
nvl(s.machine,' ? ') "Machine",
nvl(s.program,' ? ') "Program",
s.process "Foreground",p.spid "Background",X.sql_text "SQL Text"
from v$session S,
v$process P,
v$sqlarea X
where s.paddr = p.addr
and s.type != 'BACKGROUND'
and s.sql_address = x.address
and s.sql_hash_value = x.hash_value
order by s.sid
