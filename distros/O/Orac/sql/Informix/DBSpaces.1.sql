SELECT DISTINCT d.*, c.fname
FROM sysmaster:informix.sysdbspaces d, sysmaster:informix.syschunks c
WHERE d.dbsnum = c.dbsnum
