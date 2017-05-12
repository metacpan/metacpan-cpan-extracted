/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

/************************************************************************\ 
|* Procedure Name:	sp__segment				*|
|*									*|
|* Author:		sp__segment				*|
|*									*|
\************************************************************************/ 

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__segment")
begin
    drop proc sp__segment
end
go

create proc sp__segment ( @segname char(30)=NULL,
	@dont_format char(1) = null
	)
as

set nocount on

select 	name = substring(o.name, 1, 16),
       	owner = substring(user_name(o.uid),1,10),
       	row_cnt = rowcnt(i.doampg),
       	dpgs = reserved_pgs(i.id, i.doampg)*(d.low/1024),
       	ipgs = reserved_pgs(i.id, i.ioampg)*(d.low/1024),
		   segment=substring(s.name,1,13),
		   indid,
		   indname=i.name
into   #pagecounts
from   sysobjects o, sysindexes i, master.dbo.spt_values d,syssegments s 
where  i.id = o.id
and    (o.type = "U" or o.name = "syslogs")
and    d.number = 1
and    d.type = "E"
and    s.segment = i.segment
and	 s.name = isnull(@segname,s.name)

update #pagecounts
set name=owner+'.'+name
where owner!='dbo'

select distinct name, 
                row_cnt = sum(row_cnt),
                dsiz = sum(dpgs),
                isiz = sum(ipgs),
		segment
into #selres
from #pagecounts
group by name,segment
order by name,segment

select distinct segment,sum(dsiz) "Data KB",sum(isiz) "Indx KB",
		 sum(dsiz+isiz) "Total"
from #selres
group by segment
order by segment
compute sum(sum(dsiz)),sum(sum(isiz)) 

update #pagecounts
set owner='CLUSTERED',indname=name+'.'+indname
where indid=1

update #pagecounts
set owner='NON CLSTRD',indname=name+'.'+indname
where indid>=2

update #pagecounts
set owner='TABLE'
where indid=0

select 	segment,
	type=owner,
	indexname=convert(char(40),indname),
	dpgs+ipgs "Size KB"
from #pagecounts
order by segment,indexname

drop table #selres
drop table #pagecounts

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__segment to public
go
