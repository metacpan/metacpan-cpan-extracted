select name, value from v$sga
union
select 'Total SGA' name, sum(value) value from v$sga
order by 2
