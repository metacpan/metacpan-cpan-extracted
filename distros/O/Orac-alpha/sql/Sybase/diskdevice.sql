
/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	diskdevice					
|*									
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__diskdevice")
begin
    drop proc sp__diskdevice
end
go

create procedure sp__diskdevice (@devname char(30)=NULL, @dont_format char(1)=null )
as

declare @msg varchar(255)
declare @numpgsmb float		/* Number of Pages per Megabytes */
declare @tapeblocksize int	

set nocount on

select @numpgsmb = (1048576. / v.low)
from master.dbo.spt_values v
where v.number = 1 and v.type = "E"

create table #dev_tbl
(
	name		char(19),
	phyname	char(31),
	disk_size	float 	 null,
	status		int      null,
	disk_used	float    null,
	mirrored		char(1)  null
)

insert  #dev_tbl
select 	name=substring(d.name, 1,20),
	phyname = substring(d.phyname,1,30),
	disk_size=0,
	status=status,
	disk_used=0,
	mirrored=NULL
from master.dbo.sysdevices d
where name=isnull(@devname,name)

/* Parallel */
update #dev_tbl
set mirrored="P"
where status & 64 = 64

/* Serial */
update #dev_tbl
set mirrored="S"
where status & 32 = 32

/* Disabled */
update #dev_tbl
set mirrored="?"
where status & 256 = 256

/* Confused */
update #dev_tbl
set mirrored="?"
where status & 32 = 32
and	status & 512 != 512

/*  Add in its size in MB.  */
update #dev_tbl
	set disk_size = (1. + (d.high - d.low)) / @numpgsmb
	from master.dbo.sysdevices d, #dev_tbl
	where d.status & 2 = 2
	and #dev_tbl.name = d.name

update #dev_tbl
	set disk_used = ( select sum(size) 
	from master.dbo.sysusages u, master.dbo.sysdevices d
	where d.status & 2 = 2
	and vstart between low and high
	and #dev_tbl.name = d.name
	group by name ) / @numpgsmb

update #dev_tbl
set name=rtrim(name)+" ("+mirrored+")"
where mirrored is not null

if @devname is null
begin
	if @dont_format is not null
	begin
		print ""
		print "****** PHYSICAL DISK DEVICES (Mirror info after device name) ******"
	end
end

update #dev_tbl set disk_used=0 where disk_used is null

select	"Device Name"=name,
	"Physical Name"=phyname,
	size=str(disk_size,6,1)+"MB",
	alloc=str(disk_used,6,1)+"MB",
	free=str(disk_size-disk_used,6,1)+"MB"
from  #dev_tbl
where status & 2 = 2

if @devname is not null
begin
	  if exists (select  *
				 from master.dbo.sysdatabases d, master.dbo.sysusages u, 
						  master.dbo.sysdevices dv
				 where d.dbid = u.dbid
							and dv.low <= size + vstart
							and dv.high >= size + vstart - 1
							and dv.status & 2 = 2
				 			and dv.name=@devname
	  )
	  begin
			 select  db_name=d.name,
						size = size / @numpgsmb,
						usage = convert(char(18),b.name)
			 from master.dbo.sysdatabases d, master.dbo.sysusages u, master.dbo.sysdevices dv,
						master.dbo.spt_values b
			 where d.dbid = u.dbid
						and dv.low <= size + vstart
						and dv.high >= size + vstart - 1
						and dv.status & 2 = 2
						and b.type = "S"
						and u.segmap & 7 = b.number
						and dv.name=@devname
			 order by db_name,usage
	  end
	  else
	  begin
			if @dont_format is not null
			print "****** Device Unused By Any Databases ******"
	  end
end


return (0)

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__diskdevice to public
go

exit


