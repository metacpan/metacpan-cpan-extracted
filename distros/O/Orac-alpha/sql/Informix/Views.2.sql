select v.*
from informix.systables t, informix.sysviews v
where t.tabid = v.tabid 
  and t.tabname = ?
