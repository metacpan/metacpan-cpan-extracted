/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */

select  n.name          "Segment",
       r.hwmsize/1024   "High Water(KB)",
       r.optsize/1024   "Opt(KB)",
       r.shrinks        "Shrinks",
       r.aveshrink/1024 "Avg Shrink(KB)" ,
       r.rssize/1024    "Curr Size(KB)" ,
       r.extents        "Extents"
from v$rollstat r,v$rollname n
where n.usn=r.usn
