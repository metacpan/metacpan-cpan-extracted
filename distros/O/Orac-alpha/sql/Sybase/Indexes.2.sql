select distinct o.name + ":" + i.name
from   sysobjects o, sysindexes i
where  i.id   = o.id
and    o.type in ("U", "S")
and      indid > 0
and      indid < 255  /* RV added */
and      status2 & 2 != 2
order by 1
