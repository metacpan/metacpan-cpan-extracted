select distinct owner||'.'||name joined_name
from dba_errors
order by joined_name
