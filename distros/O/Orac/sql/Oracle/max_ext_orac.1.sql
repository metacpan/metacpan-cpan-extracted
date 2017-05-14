/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

select T.name,
decode(T.name,'RBS','',decode(sum(greatest(
sign(nvl((S.extsize * ( ? )),0)-Biggest),0)),0, decode(sum(greatest(sign(
nvl((S.extsize*2 * ( ? )),0)-Biggest),0)),0,'','WARN (x'||
to_char(sum(greatest(sign(nvl((S.extsize*2 * ( ? )),0)
-Biggest),0) ) )||')' ) ,'PANIC (x'||
to_char(sum(greatest(sign(nvl((S.extsize *( ? )),0)-Biggest),0)))||')')) Panic,
Tot_Blocks totblk,
Tot_Free,
Smallest,
Average,
Biggest,
max(S.extsize * ( ? )) Max_Ext
from sys.seg$ S,sys.ts$ T,(select ts#,max(F.LENGTH) * ? Biggest,
min(F.LENGTH) * ? Smallest,round(avg(F.LENGTH) * ? ,2) Average,
count(F.LENGTH) Tot_Blocks,sum(F.LENGTH) * ? Tot_Free
from sys.fet$ F group by ts#) F
where F.ts# = S.ts# (+) and F.ts# = T.ts#
group by T.name,Biggest,Smallest,Average,Tot_Blocks,Tot_Free
order by Panic,T.name
