/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	helpdbdev					
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__helpdbdev")
begin
    drop proc sp__helpdbdev
end
go

create procedure sp__helpdbdev ( @dbname char(30)=NULL ,
	@dont_format char(1) = null
	)
as

declare @msg      varchar(127)
declare @numpgsmb float		/* Number of Pages per Megabytes */

/* Check Existence */
if @dbname is not null
begin
	if not exists ( select * from master..sysdatabases
						where name=@dbname )
	begin
		select @msg="Unknown Database: "+@dbname
		print  @msg
		return 
	end
end

select @numpgsmb = (1048576. / v.low)
from master.dbo.spt_values v
where v.number = 1 and v.type = "E"

set nocount on
select  
	   "Database Name"=substring(d.name,1,15),
      "Device Name" = substring(dv.name, 1,15),
      "Size" = size / @numpgsmb,
      "Usage" = convert(char(15),b.name)
from  master..sysdatabases d, master..sysusages u, 
	   master..sysdevices dv, master..spt_values b
where d.dbid = u.dbid
      and dv.low <= size + vstart
      and dv.high >= size + vstart - 1
      and dv.status & 2 = 2
      and b.type = "S"
      and u.segmap & 7 = b.number
		and isnull(@dbname,d.name)=d.name
order by d.name,b.name

return (0)
go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__helpdbdev to public
go

exit
