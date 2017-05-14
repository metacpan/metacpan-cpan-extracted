select type "Type",
sequence||':'||line||':'||position "seq:ln:pos", 
text "Error Text"
from   dba_errors
where  owner = ? and
name  = ?
order by type,sequence,line
