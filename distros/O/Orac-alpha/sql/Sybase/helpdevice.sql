/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	helpdevice					
|*									
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__helpdevice")
begin
    drop proc sp__helpdevice
end
go

create procedure sp__helpdevice (@devname char(30)=NULL,
	@dont_format char(1) = null
	)
as

set nocount on

if @devname is null
or exists ( select * from master..sysdevices where name=@devname and status & 2!=2 )
begin
	print ""
	exec sp__dumpdevice @devname
end


if @devname is null
or exists ( select * from master..sysdevices where name=@devname and status & 2=2 )
begin
	print ""
	exec sp__diskdevice @devname
end


return (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__helpdevice to public
go

exit

