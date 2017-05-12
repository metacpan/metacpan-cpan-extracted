/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	sp__revmirror					*|
\************************************************************************/ 
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revmirror")
begin
    drop proc sp__revmirror
end
go

create procedure sp__revmirror ( @dont_format char(1) = null )
as
	set nocount on

	create table #tmp
	(
		txt varchar(255)
	)

	if exists ( select * from master.dbo.sysdevices where cntrltype=0
  						and status & 64 = 64 and status & 32 = 32 )
	insert #tmp
	select 	"disk mirror name='"+ltrim(rtrim(name))+"',mirror='"+ltrim(rtrim(mirrorname))+"'"
	from master.dbo.sysdevices
	where cntrltype=0
  	and status & 64 = 64
	and status & 32 = 32
 
	if exists ( select * from master.dbo.sysdevices where cntrltype=0
  						and status & 64 = 64 and status & 32 != 32 )
	insert #tmp
	select 	"disk mirror name='"+ltrim(rtrim(name))+"',mirror='"+ltrim(rtrim(mirrorname))+"',writes=noserial"
	from master.dbo.sysdevices
	where cntrltype=0
  	and status & 64 = 64
	and status & 32 != 32

	select * from #tmp
	drop table #tmp

return (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__revmirror to public
go

exit
