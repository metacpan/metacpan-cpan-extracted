select s.sid,
v.osuser,
v.username,
nvl(block_gets,0) + nvl(consistent_gets,0) Log_Reads,
physical_reads Phy_reads,
decode(nvl(block_gets,0) + nvl(consistent_gets,0),0,0,
round(100 * (nvl(block_gets,0) +
nvl(consistent_gets,0) - nvl(physical_reads,0) )
/ ( nvl(block_gets,0) + nvl(consistent_gets,0) ),2)) Ratio,
block_changes Phy_Writes
from v$sess_io S,v$session V
where s.sid = v.sid (+)
order by s.sid
