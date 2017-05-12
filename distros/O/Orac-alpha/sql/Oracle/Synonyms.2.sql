select synonym_name
from   dba_synonyms
where  UPPER(owner) = UPPER( ? )
order by synonym_name
