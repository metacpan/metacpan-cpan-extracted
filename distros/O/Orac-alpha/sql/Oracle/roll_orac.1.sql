/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */

select name "Rollback Segment",gets "Gets",writes "Writes",
       round(((waits/decode(writes,0,1,writes))*100),4) "waits/writes %",
       round(((waits/decode(gets,0,1,gets))*100),4) "wait/gets %"
from v$rollstat r, v$rollname n
where n.usn=r.usn
