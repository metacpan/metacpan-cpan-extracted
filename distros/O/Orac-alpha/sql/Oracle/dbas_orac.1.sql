select distinct(table_name)
from   dba_tab_columns
where  owner = 'SYS' and
( table_name like 'DBA_%' )
order by table_name
