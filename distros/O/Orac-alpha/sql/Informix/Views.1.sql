select distinct t.tabname
from informix.systables t, informix.sysviews v
where t.tabid = v.tabid 
