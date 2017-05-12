/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */

select 'CPU (recursive)' "Activity",
value/100 "Time Waited (seconds)"
from v$sysstat 
where name = 'recursive cpu usage'
union
select 'CPU (parse)',value/100 from v$sysstat
where name = 'parse time cpu'
union
select 'CPU (other)',(c.value-r.value-p.value)/100
from v$sysstat p, v$sysstat c, v$sysstat r
where p.name = 'parse time cpu'
and r.name = 'parse time cpu'
and c.name = 'CPU used by this session'
union
select 'DB file read waits',sum(time_waited)/100
from v$system_event
where event like 'db file % read'
union
select 'DB file write waits',sum(time_waited)/100
from v$system_event
where event like 'db file % write'
union
select 'Log file writes',sum(time_waited)/100
from v$system_event
where event like 'log file % write'
or event = 'log file sync'
union
select 'log file space/switch',sum(time_waited)/100
from v$system_event
where event like 'log file space/switch'
union
select 'latch waits',sum(time_waited)/100
from v$system_event
where event like 'latch free'
union
select 'Buffer waits',sum(time_waited)/100
from v$system_event
where event in ('write complete waits','free buffer waits','buffer busy waits')
union
select 'SQL*Net waits (inc remote SQL)',sum(time_waited)/100
from v$system_event
where event like 'SQL*Net%'
and event !='SQL*Net message from client'
union
select 'lock waits',sum(time_waited)/100
from v$system_event
where event = 'enqueue'
union
select 'lock waits',sum(time_waited)/100
from v$system_event
where event = 'enqueue'
union
select 'Other waits (non-idle)',sum(time_waited)/100
from v$system_event
where event not in ('Null event','client message','smon timer',
'rdbms ipc message','pmon timer','WMON goes to sleep',
'virtual circuit status','dispatcher timer',
'SQL*Net message from client',
'parallel query dequeue wait','latch free',
'enqueue','write complete waits',
'free buffer waits',
'buffer busy waits','pipe gets',
'Null event','client message','smon timer',
'rdbms ipc message','pmon timer','WMON goes to sleep',
'virtual circuit status','dispatcher timer',
'SQL*Net message from client',
'parallel query dequeue wait','latch free',
'enqueue','write complete waits',
'free buffer waits',
'buffer busy waits','pipe gets','slave wait','PL/SQL lock timer', 
'null event','Null event','rdbms ipc reply',
'Parallel Query Idle Wait - Slaves',
'KXFX: Execution Message Dequeue - Slave','slave wait')
and event not like 'db file%'
and event not like 'log file%'
and event not like 'SQL*Net%'
order by 1
