select distinct table_name from dba_triggers
where UPPER(owner) = UPPER( ? )
order by table_name
