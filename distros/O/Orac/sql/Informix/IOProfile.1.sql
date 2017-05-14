select d.name as dbsname, i.*
from sysmaster:informix.syschkio i,
     sysmaster:informix.sysdbspaces d,
     sysmaster:informix.syschunks c
where d.dbsnum = c.dbsnum
  and c.chknum = i.chunknum
order by d.name, i.chunknum
