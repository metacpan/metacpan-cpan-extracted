select name,value
from v$sysstat
where name in
(
'DBWR buffers scanned',
'DBWR checkpoints',
'DBWR cross instance writes',
'DBWR free buffers found',
'DBWR lru scans',
'DBWR make free requests',
'DBWR summed scan depth',
'DBWR timeouts',
'background checkpoints completed',
'background checkpoints started',
'dirty buffers inspected',
'free buffer inspected',
'free buffer requested',
'physical writes',
'summed dirty queue length',
'write requests')
order by name
