select b.username "Username", a.address "Address",
a.sql_text "SQL Text"
from v$sqlarea a, dba_users b
where a.command_type in (2,3,6,7,47)
and   a.parsing_user_id = b.user_id
order by 1, 2
