select i, sum(i) over (order by i ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING), sum(i) over (order by i ROWS BETWEEN 2 PRECEDING AND CURRENT ROW )
from generate_series(1,10) i;
