select 'atot' flag1,a.tablespace_name,
round(sum(a.bytes/1048576),2)
from dba_data_files a
group by a.tablespace_name
union
select 'free' flag1,b.tablespace_name,
round(sum(b.bytes/1048576),2)
from dba_free_space b
group by b.tablespace_name
order by 2,1
