/* Buffer Cache Hit ratio, less than 60, red alert, */
/* less than 70 yellow alert, above 70, green and Ok */
select round(((sum(decode(name, 'consistent gets',value,0))
+ sum(decode(name,'db block gets', value,0))
- sum(decode(name,'physical reads', value,0)))
/ ( sum(decode(name, 'consistent gets',value,0))
  + sum(decode(name,'db block gets', value,0)) ) * 100),2)
from v$sysstat
