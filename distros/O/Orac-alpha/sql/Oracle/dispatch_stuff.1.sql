select Network,
round((SUM(busy) / (SUM(busy) + SUM(idle))),20) "Busy_Rate"
from v$dispatcher
GROUP by network
