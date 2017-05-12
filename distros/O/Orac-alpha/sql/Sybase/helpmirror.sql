/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	sp__helpmirror					*|
|*									*|
|* Description:								*|
|*									*|
|* Usage:								*|
|*									*|
|* Modification History:						*|
|*									*|
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__helpmirror")
begin
    drop proc sp__helpmirror
end
go

create procedure sp__helpmirror( @dont_format char(1) = null )
as
print "******* SYBASE MIRROR INFORMATION *******"
if exists (select 1
           from master.dbo.sysdevices
	   where status & 64 = 64)
begin
	set nocount on

	print ""
	print "MIRRORED DEVICES"
	select  	Device = substring(name,1,15),
       		Pri = " " + substring("* **",(status/256)+1,1),
       		Sec = " " + substring(" ***",(status/256)+1,1),
       		Serial = "  " + substring(" *",(status & 32)/32+1,1),
       		"Mirror" = substring(mirrorname,1,35),
       		Reads = "  " + substring(" *",(status & 128)/128+1,1)
	from master.dbo.sysdevices
	where cntrltype=0
  	and status & 64 = 64

	if exists ( select * 
			from master..sysdevices where cntrltype=0
			and status & 256 = 256 )
	begin
			  print ""
			  select "ERROR: MIRROR DISABLED:"+name
			  from master..sysdevices where cntrltype=0
			  and status & 256 = 256
	end

	if exists ( select * 
			  from master..sysdevices where cntrltype=0
			  and status >= 32
			  and status & 512 != 512 )
	begin
			  print ""
			  select "ERROR: MIRROR CONFUSED:"+name
			  from master..sysdevices where cntrltype=0
			  and status >= 32
			  and status & 512 != 512
	end
end
else
begin
	print "    (NO DEVICES ARE MIRRORED)"
end
 
return (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__helpmirror to public
go

exit
