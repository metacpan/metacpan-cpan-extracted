select username from dba_users
union
select 'PUBLIC' from dual
order by 1
