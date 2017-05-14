select statistic# "Statistic#",
       name "Name",
       class "Class",
       value "Value"
from v$sysstat
where (name like '%memory%') and
(name like '%session%')
order by 1,2
