/* This is a rough detector of Slow SQL.  If disk-reads/executions goes */
/* greater than 100, then our final result drops below 300, which is */
/* a warning.  Any dr/exe > 200, gives a final result less than 200 */
/* which is a red alert */
select 400 - 
       max((round((a.disk_reads / decode(a.executions,0,1,a.executions)),
                  2))) "read_execs"
from v$sqlarea a
