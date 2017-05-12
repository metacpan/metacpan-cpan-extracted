/* replaced the original tab_det_orac.1.sql with this one because of */
/* null values that are returned by the original */
/* this script is derrived from Kevin Kitts script kkspace.1.sql */
/* and slightly changed to match the fields from the original */
/* tab_det_orac.1.sql */
/* Andre Seesink <Andre.Seesink@CreXX.nl> */
select a.tablespace_name tbsp_nam,
       replace(replace(b.file_name,'/databases/',''),'.dbf') filename ,
       round(((sum(b.bytes)/count(*))/(1024 * 1024)),2) bytes,
       round(((sum(b.bytes)/count(*) - sum(a.bytes))/(1024 * 1024)),2) used,
       round((sum(a.bytes)/(1024 * 1024)),2) free,
       round((nvl(100-(sum(nvl(a.bytes,0))/ (sum(nvl(b.bytes,0))/count(*)))*100,0)),2) pct_used
from dba_free_space a, 
     dba_data_files b
where a.tablespace_name = b.tablespace_name 
and   a.file_id = b.file_id
group by a.tablespace_name, b.file_name
order by 1
