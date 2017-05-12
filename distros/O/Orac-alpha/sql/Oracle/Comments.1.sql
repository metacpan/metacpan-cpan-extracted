select distinct owner 
from dba_tab_comments
where comments is not null
union
select distinct owner 
from dba_col_comments
where comments is not null
order by 1
