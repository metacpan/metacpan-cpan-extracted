/* Procedure copyright(c) 1996 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__stat
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__stat"
           and    type = "P")
   drop proc sp__stat

go
if exists (select * from sysobjects
           where  name = "sp__stat2"
           and    type = "P")
   drop proc sp__stat2

go
/* numbers here are in seconds for io, busy, idle */
create proc sp__stat2 (
		  @users 		int output,
		  @runnable 	int output,
		  @busy 			int output,
		  @io 			int output,
		  @idle 			int output,
		  @connections int output,
		  @pin 			int output,
		  @pout 			int output,
		  @tread 		int output,
		  @twrite 		int output,
		  @terr 			int output,
		  @now			datetime output,
			  @dont_format char(1) = null
			  )
AS
BEGIN

		  declare @ms_per_tick float
		  select @ms_per_tick = convert(int,@@timeticks/1000)

		  select @users=count(*)  
		  from master..sysprocesses
		  where suid>1

		  select @runnable=count(*) 
		  from master..sysprocesses
		  where cmd!="AWAITING COMMAND"
		  and suid>1

		  select 	
				  @busy			= ( @@cpu_busy * @ms_per_tick) / 1000,
				  @io			   = ( @@io_busy * @ms_per_tick) / 1000,
				  @idle			= ( @@idle * @ms_per_tick) / 1000,
				  @connections = @@connections,
				  @pin 			= @@pack_received,
				  @pout 			= @@pack_sent,
				  @tread 		= @@total_read,
				  @twrite 		= @@total_write,
				  @terr 			= @@total_errors,
				  @now			= getdate()

END
go

/* If batch=1 then do in a loop, if it =0 then save and print @ once */
create proc sp__stat( @cnt int=10, @dly int=2, @batch char(1)=null,
	@dont_format char(1) = null
	)
AS
BEGIN
declare @users int, @runnable int, @busy int, @io int,
			@idle int, @connections int, @pin int, @pout int,
			@tread int, @twrite int, @terr int, @now datetime

declare @last_users int, @last_runnable int, @last_busy int, @last_io int,
			@last_idle int, @last_connections int, @last_pin int, @last_pout int,
			@last_tread int, @last_twrite int, @last_terr int, @last_now datetime

declare @secs int

/* Process Stats */
set nocount on

	/* Initialize */
	exec sp__stat2
		  @last_users		output,
		  @last_runnable 	output,
		  @last_busy 		output,
		  @last_io 			output,
		  @last_idle 		output,
		  @last_connections output,
		  @last_pin 		output,
		  @last_pout 		output,
		  @last_tread 		output,
		  @last_twrite 	output,
		  @last_terr 		output,
		  @last_now				output

		create table #stats
		(
				  Dt      datetime,
				  Usrs	 char(4),
				  Runbl   char(3),
				  Cpu     char(4),
				  IO      char(4),
				  Secs    char(4),
				  conn    char(4),
				  net_in  char(4),
				  net_out char(4),
				  reads   char(4),
				  writes  char(4),
				  errors  char(4)
		)

While @cnt > 0
begin
	select @cnt = @cnt - 1
	if @dly=5
		waitfor delay '00:00:05'
	else if @dly=10
		waitfor delay '00:00:10'
	else if @dly=1
		waitfor delay '00:00:01'
	else if @dly=2
		waitfor delay '00:00:02'
	else if @dly=3
		waitfor delay '00:00:03'
	else if @dly=4
		waitfor delay '00:00:04'
	else if @dly=30
		waitfor delay '00:00:30'
	else if @dly=60
		waitfor delay '00:01:00'
	else
	begin
		print "Delay must be 1,2,3,4,5,10,30, or 60"
		return
	end

	exec sp__stat2
		  @users 		output,
		  @runnable 	output,
		  @busy 			output,
		  @io 			output,
		  @idle 			output,
		  @connections output,
		  @pin 			output,
		  @pout 			output,
		  @tread 		output,
		  @twrite 		output,
		  @terr 			output,
		  @now			output

	select @secs = @busy - @last_busy + @io - @last_io + @idle - @last_idle
	if @secs = 0
		select @secs=1

	if @batch is null
		select
			"Usrs"	 = convert(char(4), @users),
			"Run"     = convert(char(3), @runnable),
			"%Cpu"     = convert(char(4), (100*(@busy-@last_busy))/@secs),
			"%IO"      = convert(char(4), (100*(@io-@last_io))/@secs),
			"Secs"    = convert(char(4), datediff(ss,@last_now,@now)),
			"Conn"    = convert(char(4), @connections - @last_connections),
			"Net in"  = convert(char(4), @pin 		- @last_pin),
			"Net out" = convert(char(4), @pout 		- @last_pout),
			"Reads"   = convert(char(4), @tread 	- @last_tread),
			"Writes"  = convert(char(4), @twrite 	- @last_twrite),
			"Errors"  = convert(char(4), @terr 		- @last_terr)
	else
		insert #stats
		select
				  Dt      = getdate(),
				  Usrs	 = convert(char(4), @users),
				  Run     = convert(char(3), @runnable),
				  Cpu     = convert(char(4), (100*(@busy - @last_busy))/@secs),
				  IO      = convert(char(4), (100*(@io - @last_io))/@secs),
				  Secs    = convert(char(4), datediff(ss,@last_now,@now)),
				  conn    = convert(char(4), @connections - @last_connections),
				  net_in  = convert(char(4), @pin 		- @last_pin),
				  net_out = convert(char(4), @pout 		- @last_pout),
				  reads   = convert(char(4), @tread 	- @last_tread),
				  writes  = convert(char(4), @twrite 	- @last_twrite),
				  errors  = convert(char(4), @terr 		- @last_terr)

	select
		  @last_busy 		= @busy,
		  @last_io 			= @io,
		  @last_idle 		= @idle,
		  @last_connections = @connections,
		  @last_pin 		= @pin,
		  @last_pout 		= @pout,
		  @last_tread 		= @tread,
		  @last_twrite 	= @twrite,
		  @last_terr 		= @terr,
		  @last_now 		= @now

end

if @batch is not null
		select  Date=convert(char(8),Dt,8),
				  Usrs	 ,
				  "Run" = Runbl,
				  "%Cpu"=Cpu     ,
				  "%IO"=IO      ,
				  Secs    ,
				  connections=conn    ,
				  "net in"=net_in  ,
				  "net out"=net_out ,
				  reads   ,
				  writes  ,
				  errors 
		from #stats
		order by Dt

return(0)

END
go

grant execute on sp__stat  TO public
go
grant execute on sp__stat2  TO public
go
