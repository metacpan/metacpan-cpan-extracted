create procedure sp__revdevice ( @dont_format char(1) = null)
as

set nocount on

create table #tmp
(
	txt	varchar(127),
	grp   int
)

create table #dev_tbl
(
	name		char(30) not null,
	phyname		varchar(127),
	disk_size	int 	 null,
	status		int      null,
	vdevno		tinyint		 null
)

insert  #dev_tbl
select 	name=d.name,
	phyname = d.phyname,
	disk_size = 1. + (d.high - d.low),
	status=status,
	vdevno =  convert(tinyint, substring(convert(binary(4), d.low), v.low, 1))
from master.dbo.sysdevices d,
	   master..spt_values v
    where  v.type = "E"
    and	   v.number = 3

insert #tmp values("/********* BACKUP DEVICES *********/",1)

insert #tmp
select 	"exec sp_addumpdevice 'disk','"+ltrim(rtrim(d.name))+"','"+ltrim(rtrim(d.phyname))+"',2",2
from #dev_tbl d
where d.status & 2 != 2
and	d.name not in ("diskdump","tapedump1","tapedump2")

insert #tmp values("",3)
insert #tmp values("/****** PHYSICAL DISK DEVICES ******/",4)

insert #tmp
select	"disk init name='"+ltrim(rtrim(name))+"',"+
	"physname='"+ltrim(rtrim(phyname))+"',"+
	"vdevno="+convert(char(6),vdevno)+","+
	"size="+convert(char(20),disk_size),5
from  #dev_tbl
where status & 2 = 2
and   vdevno!=0

select txt from #tmp order by grp
return (0)
