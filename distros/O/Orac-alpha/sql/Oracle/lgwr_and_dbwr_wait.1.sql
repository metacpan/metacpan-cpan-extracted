select event Wait_Event,
total_waits Tot_Waits,
time_waited Times_Waited
from v$system_event
where event like '%file%'
order by total_waits desc
