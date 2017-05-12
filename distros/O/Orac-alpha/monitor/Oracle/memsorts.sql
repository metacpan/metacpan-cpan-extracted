/* This finds out the percentage of sorts occurring in memory */
/* Thanks to Duncan Lawie */
select round((sum( decode( name, 'sorts (memory)', value, 0 ) )
                           / (
              sum( decode( name, 'sorts (memory)', value, 0 ) )  +
              sum( decode( name, 'sorts (disk)', value, 0 ) )
                              ) * 100),2)
from v$sysstat
