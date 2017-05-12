select file_name
from   dba_data_files
where  UPPER(tablespace_name) = UPPER( ? )
order by 1
