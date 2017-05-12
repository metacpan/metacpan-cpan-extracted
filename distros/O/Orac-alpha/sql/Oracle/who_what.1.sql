select /*+ ORDERED */
s.username "Hold User",
s.osuser "OS User",
s.serial# "Ser#",
s.sid "Sid",
X.sql_text "SQL Text",
nvl(s.program,'?') "Program",
nvl(s.machine,'?') "Machine",
s.process "Foreground Process",
p.spid "Background Spid"
from v$session S,
v$process P,
v$sqlarea X
where s.osuser like lower(nvl( ? ,'%'))
and s.username like UPPER(nvl( ? ,'%'))
and s.sid like nvl( ? ,'%')
and s.paddr = p.addr
and s.type != 'BACKGROUND'
and s.sql_address = x.address
and s.sql_hash_value = x.hash_value
order by s.sid
