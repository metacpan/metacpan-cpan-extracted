SELECT A.tablespace_name "Tablespace Name",
       round((sum(a.bytes)/(1024 * 1024)),2) "Free Mb"
from user_free_space a
group by a.tablespace_name
