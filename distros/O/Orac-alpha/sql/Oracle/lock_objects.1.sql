select s.osuser "OS User",
s.username "Username",
s.serial# "Serial#",
s.sid "Sid",
a.owner||'.'||a.object "Object Name",
'=> '||a.type "Lock Mode"
from v$session s, v$access a
where a.sid = s.sid
order by 6,1,2,3,4,5
