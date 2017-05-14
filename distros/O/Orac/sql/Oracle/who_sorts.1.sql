select vs.username User_Name,
vs.osuser OS_User,
vsn.name Stat_Name,
vss.value Sess_Value
from v$session vs,v$sesstat vss,v$statname vsn
where (vss.statistic#=vsn.statistic#) and
(vs.sid = vss.sid) and
(vsn.name like '%sort%')
order by 2,3
