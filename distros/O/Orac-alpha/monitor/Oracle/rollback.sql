/* This checks the waits/gets ratio for Rollback segments */
/* Anything less than 99 (%) gives a red warning, anything */
/* else less than 99.5 (%) gives a yellow warning, and */
/* everything above 99.5 (%) gives green for Ok */
select 100.00 - (round((sum(waits) / (sum(gets) + .00000001)) * 100,2))
from v$rollstat
