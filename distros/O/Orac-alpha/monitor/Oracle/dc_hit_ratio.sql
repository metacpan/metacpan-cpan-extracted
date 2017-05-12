/* Dictionary Cache Hit Ratio (Row Cache) */
/* Follows a generalist ruling that you should try and keep */
/* the row cache (dictionary cache) hit ratio at least less */
/* than 10-15%, therefore less than 85 gets an alert, less than */
/* 90 gets a warning */
select round(((sum(gets-getmisses)/sum(gets))*100),2) dc_hit_ratio
from v$rowcache
