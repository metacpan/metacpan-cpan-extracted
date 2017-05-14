select t.tabname, i.idxname, i.owner, i.idxtype, i.clustered, i.levels,
       i.leaves, i.nunique, i.clust
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part1) and c.tabid = i.tabid) col1
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part2) and c.tabid = i.tabid) col2
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part3) and c.tabid = i.tabid) col3
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part4) and c.tabid = i.tabid) col4
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part5) and c.tabid = i.tabid) col5
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part6) and c.tabid = i.tabid) col6
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part7) and c.tabid = i.tabid) col7
       ,(select c.colname from informix.syscolumns c where c.colno = abs(i.part8) and c.tabid = i.tabid) col8
from informix.sysindexes i, informix.systables t
where t.tabtype = 'T'
and t.tabid = i.tabid
{
idxtype = U = Unique
          D = Duplicates
if a partX is negative, it's in descending order
}
