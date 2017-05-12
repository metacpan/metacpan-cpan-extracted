select substr(s1.username,1,12) "Wait User",
substr(s1.osuser,1,8) "OS User",
s1.serial# "Ser#",
substr(to_char(w.sid),1,5) "Sid",
P1.spid "Pid",
'=>' "=>",
substr(s2.username,1,12) "Hold User",
substr(s2.osuser,1,8) "OS User",
s2.serial# "Ser#",
substr(to_char(h.sid),1,5) "Sid",
P2.spid "Pid"
from v$process P1,v$process P2,
v$session S1,v$session S2,
v$lock w,v$lock h
where h.lmode is not null
and w.request is not null
and h.lmode != 0
and w.request != 0
and w.type (+) = h.type
and w.id1 (+) = h.id1
and w.id2 (+) = h.id2
and w.sid = S1.sid (+)
and h.sid = S2.sid (+)
and S1.paddr = P1.addr (+)
and S2.paddr = P2.addr (+)
