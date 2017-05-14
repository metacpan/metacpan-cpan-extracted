select sequence_name
from   dba_sequences
where  UPPER(sequence_owner) = UPPER( ? )
order by sequence_name
