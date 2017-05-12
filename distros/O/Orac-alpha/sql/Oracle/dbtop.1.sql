/* Script supplied by Mladen Gogala */
/* originally embedded in a Perl script written by Guy Harrison */
/* (adapted heavily for use within Orac) */

select /* +ORDERED */ si.sid "Sid",
       s.username "User",
       si.physical_reads "PhysRds",
       si.block_gets "BlkGts",
       si.consistent_gets "ConsGts",
       si.block_changes "BlkChngs",
       si.consistent_changes "ConsChngs",
       decode(nvl(p.background,0),1,bg.name, s.program ) "S_Prog",
       p.program "P_Prog",
       s.osuser "OSusr",
       s.process "Process",
       p.spid "Spid",
       s.serial# "Ser#",
       s.status "Status",
       s.machine "Machine",
       nvl(bg.name,'NA') "Name",
       ss.value "Value"
  from v$sess_io si,
       v$session s,
       v$process p,
       v$sesstat ss,
       v$bgprocess bg
 where si.sid=s.sid
   and p.addr=s.paddr
   and bg.paddr(+)=p.addr
   and ss.sid=s.sid
   and ss.statistic#=12
order by si.physical_reads desc
