/* Kevin Kitts <kkitts@his.com> */
select a.tablespace_name "Tablespace Name", a.file_id "File",
       round(((sum(b.bytes)/count(*))/(1024 * 1024)),2) "Bytes Mb",
       round(((sum(b.bytes)/count(*) - sum(a.bytes))/(1024 * 1024)),2) "Used Mb",
       round((sum(a.bytes)/(1024 * 1024)),2) "Free Mb",
       round((nvl(100-(sum(nvl(a.bytes,0))/ (sum(nvl(b.bytes,0))/count(*)))*100,0)),2)||'%' "Pct Used"
from dba_free_space a, dba_data_files b
where a.tablespace_name = b.tablespace_name and a.file_id = b.file_id
group by a.tablespace_name, a.file_id
order by 1
