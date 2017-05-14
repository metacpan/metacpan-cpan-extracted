select dbsname, owner, tabname, count(*) as num_locks
from sysmaster:informix.syslocks
group by 1, 2, 3
order by 1, 2, 3, 4
