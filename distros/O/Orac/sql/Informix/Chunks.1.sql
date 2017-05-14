SELECT c.*, d.name as dbspace
FROM sysmaster:informix.syschunks c, sysmaster:informix.sysdbspaces d
WHERE d.dbsnum = c.dbsnum
