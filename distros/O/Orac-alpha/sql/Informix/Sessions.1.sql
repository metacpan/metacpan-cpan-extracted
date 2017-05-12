{
select sid, username, uid, pid, hostname, tty, connected, is_wlatch, is_wlock,
       is_wbuff, is_wckpt, is_wlogbuf, is_wtrans, is_monitor, is_incrit
}
select sid, username, uid, pid, hostname, tty, connected, state
from sysmaster:"informix".syssessions
