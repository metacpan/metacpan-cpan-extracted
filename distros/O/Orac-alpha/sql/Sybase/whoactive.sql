/*********************************************************************
* Stored procedure  sp__whoactive  for Sybase or Microsoft SQL Server 
* Author:              Andrew Zanevsky, AZ Databases, Inc.
*                      CompuServe: 71232,3446                        
*                      INTERNET: 71232.3446@compuserve.com           
* Date Written:        Version 1.0  03/15/1994
* Revision History:    Version 2.0  03/21/1995 - added blkd column
*
* DESCRIPTION:
* Monitors indicators of processes activity for a specified
* period of time (5-60 seconds) and answers the question:  
* "Which processes are active?".                           
* Activity indicators: CPU, I/O, # locks, command executed, status.  
* Blocks are also reported, but not considered 'activity indicators'.
* - blkd column of the result set shows spid of the blocking process,
*        (same as blk column in sp_who result set);
* - bcnt column of the result set shows the count of other processes
*        blocked by the process.
* If any indicator of a process (other than blocks information) 
* changes during the monitoring interval, then it is considered 
* active. Otherwise - inactive. Therefore, processes shown in 
* sysprocesses table as doing DELETE, SELECT, etc., and with 
* 'runnable' status, but not allocating new locks and not consuming 
* CPU and I/O will be reported as inactive.            
*                                                                    
* WARNING:                                                           
* This procedure uses WAITFOR command. Some SQL Server versions      
* behave inconsistently when more than 3 WAITFOR's are concurrently  
* active. Possible misbehavior - premature finish of one or more of  
* WAITFOR commands (the following command starts).                   
* It is however safe to execute this procedure if you are not using  
* WAITFOR to schedule SQL Server jobs or to delay stored procedures. 
*                                                                    
* PARAMETERS:                                                        
* @loginame - optional login name; value 'active' indicates that     
*             only active processes should be shown; default = 'all'.
*             (I hope that you don't have logins 'active' and 'all'.)
* @delay    - monitoring interval in seconds: [5,10,20,60],          
*             default = 5 seconds.                                   
* Examples:                                                          
*      sp__whoactive          - monitor all processes for 5 seconds,  
*      sp__whoactive 'all',60 - monitor all processes for 60 seconds, 
*      sp__whoactive sa, 20   - monitor sa logins for 20 seconds,     
*      sp__whoactive active   - monitor all processes for 5 seconds,  
*                              and report only active ones           
**********************************************************************/

:r database
go
:r dumpdb
go

if exists (select * 
         from   sysobjects 
         where  type = 'P'
         and    name = "sp__whoactive")
begin
    drop procedure sp__whoactive
end
go
/* sp__whoactive  v2.0  03/21/1995
** Author: Andrew Zanevsky, AZ Databases, Inc. 
** Internet: 71232.3446@compuserve.com */
create proc sp__whoactive
        @loginame varchar(30) = 'all', /* 'all','active' or login name*/
        @delay    tinyint     = 5      /* 5/10/20/60 seconds          */,
			  @dont_format char(1) = null

as

declare @t1 datetime, @t2 datetime, @msg varchar(80)

set NOCOUNT ON

create table #locks       ( spid smallint, locks int )
create table #total_locks ( spid smallint, locks char(5) )
create table #processes   ( spid smallint, suid smallint,
                            cpu1 int     , cpu2 int     , 
                            io1  int     , io2  int     ,
                            cmd1 char(16), cmd2 char(16), 
                            sts1 char(16), sts2 char(16),
                                           blk2 smallint  )
create table #total_prcs  ( spid smallint, suid smallint,
                            cpu  int     , 
                            io   int     , 
                            cmd1 char(16), cmd2 char(16), 
                            sts1 char(16), sts2 char(16),
                                           blk2 int  )
create table #blocks      ( spid smallint, blocking char(4) )

insert  #locks 
select  distinct spid, -count(*)
from    master.dbo.syslocks 
group by spid 

select  @t1 = getdate()

insert  #processes
select  spid, 0, cpu, 0, physical_io, 0, cmd, ' logged off', status, ' ', 0
from    master.dbo.sysprocesses
where   @loginame in ( 'all', 'active' )
or      suid = isnull( suser_id( @loginame ), -1 )

if @delay <= 5
        waitfor delay '00:00:05'
else if @delay <= 10
        waitfor delay '00:00:10'
else if @delay <= 20
        waitfor delay '00:00:20'
else 
        waitfor delay '00:01:00'

insert  #locks 
select  distinct spid, count(*)
from    master.dbo.syslocks 
group by spid 

select  @t2 = getdate()

insert  #processes
select  spid, suid, 0, cpu, 0, physical_io, ' ', cmd, ' ', status, blocked
from    master.dbo.sysprocesses
where   @loginame in ( 'all', 'active' )
or      suid = isnull( suser_id( @loginame ), -1 )

insert  #locks 
select  distinct spid, 0 from #processes

insert  #total_locks 
select  spid, str( sum( locks ), 5 ) 
from    #locks 
group by spid

insert  #blocks 
select  blk2, str( count(*), 4 ) 
from    #processes 
where   blk2 != 0 
group by blk2

insert  #blocks      
select  distinct spid, str( 0, 4 ) 
from    #locks 
where   spid not in ( select spid from #blocks )

insert  #total_prcs     
select  spid, max(suid), 
        sum(cpu2)-sum(cpu1), 
        sum(io2 )-sum(io1 ), 
        max(cmd1), max(cmd2), 
        max(sts1), max(sts2),
                   max(blk2)
from    #processes 
group by spid

select  @msg = @@servername + '    ' + convert( char(19), getdate() ) 
select  @msg = 'Activity indicators of ' + @loginame + 
               ' logins during the last ' + 
               str( datediff( ss, @t1, @t2 ), 2 ) + ' seconds'

select  str( a.spid,  5 ) spid,
        substring(suser_name(a.suid),1,12) loginame,
        b.locks,
        str( a.cpu  , 5 ) cpu,
        str( a.io   , 6 ) 'i/o',
        a.cmd2 cmd,
        substring( a.sts2, 1, 8 ) status,
        str( a.blk2 , 4 ) blkd,
        c.blocking bcnt,
        substring( ' *@@', sign( 
                abs( convert( smallint, b.locks ) ) +
                abs(a.cpu) + 
                abs(a.io) + 
                ( 1 - sign( charindex( a.cmd1, a.cmd2 ) ) )+ 
                ( 1 - sign( charindex( a.sts1, a.sts2 ) ) )  ) 
                + 3 - 2 * sign( abs( @@spid - a.spid ) ), 1 ) 'a'
from    #total_prcs a, #total_locks b, #blocks c
where   a.spid = b.spid
and     a.spid = c.spid
and   ( @loginame != 'active'
or      convert( smallint, b.locks ) != 0
or      a.cpu   != 0
or      a.io    != 0
or      a.cmd1  != a.cmd2
or      a.sts1  != a.sts2 )

select  @msg = 'Total: ' + str( @@rowcount, 3 ) + 
               ' process(es).  (* - active, @ - this process.)'
print   @msg

drop table #locks     
drop table #total_locks     
drop table #total_prcs 
drop table #processes 
drop table #blocks     
go
