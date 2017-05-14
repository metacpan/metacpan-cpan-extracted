select ts.name tspace,
tf.blocks blocks,
sum(f.length) free,
count(*) pieces,
max(f.length) biggest,
min(f.length) smallest,
round(avg(f.length)) average,
sum(decode(sign(f.length-5),-1,f.length,0)) dead
from sys.fet$ f,
sys.file$ tf,
sys.ts$ ts
where ts.ts# = f.ts#
and ts.ts# = tf.ts#
group by ts.name,tf.blocks
