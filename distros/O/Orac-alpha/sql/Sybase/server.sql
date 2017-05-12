/* Procedure copyright(c) 1995 by Edward M Barlow */


/************************************************************************\
|* Procedure Name:      sp__server                                  	*|
\************************************************************************/
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__server")
begin
    drop proc sp__server
end
go

create procedure sp__server    ( @dont_format char(1) = null)
as
begin
	print "******* SYBASE VERSION *******"
	print @@version

	print ""
	set nocount on
	exec sp__helpdb
	print ""
	set nocount on
	exec sp__helpdbdev

	print ""
	set nocount on
	exec sp__helpdevice

	print ""
	set nocount on
	exec sp__helpmirror

	print ""
	set nocount on
	exec sp__vdevno

	print ""
	set nocount on
	exec sp__helpsegment

	print ""
	set nocount on
	exec sp__helplogin

    return (0)
end
go

grant execute on sp__server to public
go
