select b.data
from informix.systriggers t, informix.systrigbody b
where a.trigid = b.trigid
  and a.trigname = ?
  and (b.datakey = 'D' or b.datakey = 'A')
