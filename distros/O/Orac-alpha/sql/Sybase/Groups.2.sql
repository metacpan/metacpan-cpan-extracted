select Group_name = name
from sysusers G
where (G.uid > 16383 or G.uid = 0) and
       not exists (select *
       from sysroles R
       where G.uid = R.lrid)
order by name
