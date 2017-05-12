select c.colname from informix.syscolumns c, informix.systables t
where t.tabtype = 'T'
  and t.tabid = c.tabid
    and t.tabname = ?
