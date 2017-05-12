select r.usn "Usn",
r.name "Name",
s.osuser "OS User",
s.username "Username",
s.serial# "Serial#",
s.sid "Sid",
x.extents "Extents",
x.extends "Extends",
x.waits "Waits",
x.shrinks "Shrinks",
x.wraps "Wraps"
from v$rollstat X,
v$rollname R,
v$session S,
v$transaction T
where t.addr = s.taddr (+)
and x.usn (+) = r.usn
and t.xidusn (+) = r.usn
order by r.usn
