select username,
round((100*(consistent_gets+block_gets-physical_reads)/
(consistent_gets+block_gets)), 2) HitRatio
from v$session, v$sess_io
where v$session.sid = v$sess_io.sid
and (consistent_gets + block_gets) > 0
and username is not null
