select NAME, nvl(VALUE,'<NULL>') value
from v$parameter
order by name
