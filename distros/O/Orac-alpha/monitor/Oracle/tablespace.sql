/* This finds out the lowest percentage-to-go figure */
/* from amongst all the tablespaces */
SELECT  min((100 - (round((100 * (b.used / a.total)), 2)))) pct_to_go
FROM    (SELECT  tablespace_name, SUM (bytes) total
         FROM    dba_data_files
         group by tablespace_name) a,
        (SELECT  tablespace_name, SUM (bytes) used
         FROM    dba_segments
         group by tablespace_name) b
WHERE   a.tablespace_name = b.tablespace_name (+)
