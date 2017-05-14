select username "UserName",
tablespace_name "Tablespace Name",
bytes / 1024 "Quota(MB)",
decode(max_bytes,-1,'unlimited',rpad(max_bytes / 1024,9)) "Max Quota(MB)"
from dba_ts_quotas
order by 1,2
