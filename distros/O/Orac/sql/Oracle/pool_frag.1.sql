/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */

select 'recursive calls/total calls' "Calls Ratio",
round(((rc.value/(rc.value+uc.value))*100),4) "Value"
from v$sysstat rc, v$sysstat uc
where rc.name='recursive calls'
and uc.name='user calls'
