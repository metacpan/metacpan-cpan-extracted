/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */

select event "Event Name",
total_waits "Waits",
time_waited "TimeWaited (s)",
average_wait "AvgWait (s*100)"
from v$system_event
where event not in ('Null event','client message','smon timer',
'rdbms ipc message','pmon timer','WMON goes to sleep',
'virtual circuit status','dispatcher timer',
'SQL*Net message from client','parallel query dequeue wait',
'pipe get','PL/SQL lock timer','null event',
'Null event','rdbms ipc reply', 'Parallel Query Idle Wait - Slaves',
'KXFX: Execution Message Dequeue - Slave','slave wait')
order by time_waited desc, total_waits desc
