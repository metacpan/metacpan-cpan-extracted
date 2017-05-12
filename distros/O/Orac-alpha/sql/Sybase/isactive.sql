/*********************************************************************
* Stored procedure  sp__isactive  for Sybase or Microsoft SQL Server 
* Author:              Andrew Zanevsky, AZ Databases, Inc.
*                      CompuServe: 71232,3446                        
*                      INTERNET: 71232.3446@compuserve.com           
* Date Written:        Version 1.0  02/22/1994
* Revision History:    Version 2.0  03/16/1995 - check if blocked
*
* DESCRIPTION:
* Monitors indicators of a given process activity for a specified
* period of time (5-60 seconds) and reports whether the process
* is active and if it is blocked.
* Activity indicators: CPU, I/O, # locks, command executed, status.  
* If any indicator of a process changes during the monitoring        
* interval, then it is considered active. Otherwise - inactive.      
* Therefore processes shown in sysprocesses as doing DELETE, SELECT, 
* etc., and with 'runnable' status, but not allocating new locks and 
* not consuming CPU and I/O will be reported as inactive.            
*                                                                    
* WARNING:                                                           
* This procedure uses WAITFOR command. Some SQL Server versions      
* behave inconsistently when more than 3 WAITFOR's are concurrently  
* active. Possible misbehavior - premature finish of one or more of  
* WAITFOR commands (the following command starts).                   
* It is however safe to execute this procedure if you are not using  
* WAITFOR to schedule SQL Server jobs or to delay stored procedures. 
*                                                                    
* PARAMETERS:  @spid  - system process id (as shown by sp_who)       
*              @delay - monitoring interval in seconds: [5,10,20,60],
*                       default = 5 seconds                          
**********************************************************************/
:r database
go
:r dumpdb
go

if exists (select * 
         from   sysobjects 
         where  type = 'P'
         and    name = "sp__isactive")
begin
    drop procedure sp__isactive
end
go
go
/* sp__isactive  v2.0  03/16/1995
** Author: Andrew Zanevsky, AZ Databases, Inc. 
** Internet: 71232.3446@compuserve.com */
create proc sp__isactive
        @spid   smallint,              /* system process id           */
        @delay  tinyint     = 5        /* 5/10/20/60 seconds          */,
		  @dont_format char(1) = null

as

declare @n1   smallint, @n2   smallint,
        @cpu1 int,      @cpu2 int,
        @io1  int,      @io2  int,
        @cmd1 char(16), @cmd2 char(16),
        @sts1 char(16), @sts2 char(16),
        @t1   datetime, @t2   datetime,
                        @blk2 smallint,
        @msg  varchar(80)

set rowcount 1
select  @n1 = count(*) from master.dbo.syslocks where spid = @spid
set rowcount 0
select  @t1 = getdate(), 
        @cpu1 = cpu, @io1 = physical_io, @cmd1 = cmd, @sts1 = status
from master.dbo.sysprocesses where spid = @spid

if @delay <= 5
        waitfor delay '00:00:05'
else if @delay <= 10
        waitfor delay '00:00:10'
else if @delay <= 20
        waitfor delay '00:00:20'
else 
        waitfor delay '00:01:00'

set rowcount 1
select  @n2 = count(*) from master.dbo.syslocks where spid = @spid
set rowcount 0
select  @t2 = getdate(), 
        @cpu2 = cpu, @io2 = physical_io, @cmd2 = cmd, @sts2 = status,
        @blk2 = blocked
from master.dbo.sysprocesses where spid = @spid

if @cpu1 is null and @cpu2 is not null 
        select @msg = ' Process has just been started'
else if @cpu2 is null and @cpu1 is null
        select @msg = ' Process does not exist'
else if @cpu2 is null and @cpu1 is not null
        select @msg = ' Process was just active, but does not exist now'
else if @n1=@n2 and @cpu1=@cpu2 and @io1=@io2 and @cmd1=@cmd2 and @sts1=@sts2
        select @msg = ' Process shows no activity'
else
        select @msg = ' Process is active'

if isnull( @blk2, 0 ) > 0
        select @msg = @msg + ' and is currently blocked'

if @cpu1 is not null or @cpu2 is not null
select  convert( char(8), @t1, 108 ) 'time', 
        @n1 'locks', @cpu1 'cpu', @io1 'phys_io', @cmd1 'cmd', @sts1 'status'
where   @cpu1 is not null
union all
select  convert( char(8), @t2, 108 ) 'time', 
        @n2 'locks', @cpu2 'cpu', @io2 'phys_io', @cmd2 'cmd', @sts2 'status'
where   @cpu2 is not null
union all
select  '~+' + ltrim( str( datediff( ss, @t1, @t2 ) ) ) + ' sec' 'time',
        @n2-@n1 'locks', @cpu2-@cpu1 'cpu', @io2-@io1 'phys_io', 
        substring( 'changed       ', charindex( @cmd1,@cmd2 )*7+1,7 ) 'cmd',
        substring( 'changed       ', charindex( @sts1,@sts2 )*7+1,7 ) 'status'
where   @cpu1 is not null  and  @cpu2 is not null 

print @msg

go
grant execute on sp__isactive to public
go


