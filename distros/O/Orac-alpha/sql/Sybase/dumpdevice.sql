/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	dumpdevice					
|*									
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__dumpdevice")
begin
    drop proc sp__dumpdevice
end
go

create procedure sp__dumpdevice (@devname char(30)=NULL, @dont_format char(1)=null )
as
set nocount on

	if @dont_format is not null
		print "********* BACKUP DEVICES *********"

	select 	"Device Name"=substring(d.name, 1,20),
		"Physical Name"= substring(d.phyname,1,50)
	from master.dbo.sysdevices d
	where d.status & 2 != 2
	and   isnull(@devname,name) = name

return (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__dumpdevice to public
go

exit

