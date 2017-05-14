select to_char((round((a.disk_reads / decode(a.executions,0,1,a.executions)),
                      2)),'999,999,999.99') "Average",
       to_char(a.disk_reads,'999,999,999') "Disk Reads",
       to_char(a.executions,'999,999,999') "Executions",
       to_char((round(((a.disk_reads / decode(a.executions,0,1,a.executions)) / 50) ,
                      2)),'999,999,999.99') "Est. Response (secs)",
       b.username,
       a.sql_text "SQL Text"
from v$sqlarea a, dba_users b
where (a.disk_reads / decode(a.executions,0,1,a.executions)) > 200
and a.parsing_user_id = b.user_id
order by 1 desc
