select b.*, t.tabname, c.colname, c.coltype
from informix.syscolumns c, informix.systables t, informix.sysblobs b
where t.tabtype = 'T'
  and t.tabid = c.tabid
  and t.tabid = b.tabid
  and c.colno = b.colno
