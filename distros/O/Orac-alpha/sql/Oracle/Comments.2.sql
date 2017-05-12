select distinct a.object_name
from dba_objects a
where UPPER(a.owner) = UPPER( ? )
and ( a.object_name IN ( select b.table_name
                        from dba_tab_comments b
                        where b.owner = a.owner
                        and b.comments is not null )
      OR
      a.object_name IN ( select c.table_name
                        from dba_col_comments c
                        where c.owner = a.owner
                        and c.comments is not null )
    )
order by 1
