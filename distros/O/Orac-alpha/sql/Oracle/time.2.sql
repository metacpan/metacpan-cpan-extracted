select 'Database Startup At '|| 
to_char(startup_time,'HH24:MI:SS DD/MM/YY') start_time
from v$instance
