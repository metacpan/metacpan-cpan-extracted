select r.usn,r.name,s.osuser,
s.username,s.sid,x.extents extnts,
x.extends extnds,x.waits,x.shrinks shrnks,
x.wraps wrps
from v$rollstat X,
v$rollname R,
v$session S,
v$transaction T
where t.addr = s.taddr (+)
and x.usn (+) = r.usn
and t.xidusn (+) = r.usn
order by r.usn
