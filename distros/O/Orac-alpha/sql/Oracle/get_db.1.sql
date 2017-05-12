/* Thanks to Edmund Mergl */
select value blocksize
from v$parameter
where name = 'db_block_size'
