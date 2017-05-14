/* Adapted From Oracle SQL High-Performance Tuning */
/* Guy Harrison */
/* ISBN 0-13-614231-1 */
/* This Book comes with a Five Star Orac Rating */

select s.sid "Sid",
       s.process "Client Pid",
       p.spid "Server Pid", 
       s.username "User Name",
       decode(nvl(p.background,0),1,bg.name, s.program ) "Program",
       round((ss.value/100),2) "CPU Secs",
       physical_reads "Disk IO"
  from v$process p,v$session s,v$sesstat ss,v$sess_io si,v$bgprocess bg
 where s.paddr=p.addr
   and ss.sid=s.sid
   and ss.statistic#=12
   and si.sid=s.sid
   and bg.paddr(+)=p.addr
 order by ss.value desc
