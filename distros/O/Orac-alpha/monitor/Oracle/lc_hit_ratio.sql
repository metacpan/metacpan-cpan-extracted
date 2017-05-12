/* Library Cache Hit Ratio */
/* Less than 98, red alert, less than 99, yellow alert, > 99 */
/* is Ok. */
select round(((1-sum(reloads)/sum(pins))*100),2) lc_hit_ratio
from v$librarycache
