
select id,attribute_001,attribute_002
from __table__
where (attribute_001 between 100 and 900)
    and (attribute_002 between 300 and 900)
    and (attribute_003 < 800 or attribute_003 > 900)
order by id;

