/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__indexspace
**
** Created By  : Ed Barlow
**
******************************************************************************/
:r database
go
:r dumpdb
go

IF EXISTS (SELECT * FROM sysobjects
           WHERE  name = "sp__indexspace"
           AND    type = "P")
   DROP PROC sp__indexspace
go

CREATE PROC sp__indexspace( 
                @objname        varchar(92) = NULL ,
					@dont_format char(1) = null
						 )
AS 
BEGIN

declare @pagesize int			/* Bytes Per Page */

set nocount on

select  @pagesize = low
from    master..spt_values
where   number = 1
and     type = "E"

select name = o.name,
		 idxname = i.name,
       owner_id = o.uid,
       row_cnt = rowcnt(i.doampg),
       reserved = (reserved_pgs(i.id, i.doampg) +
              	   reserved_pgs(i.id, i.ioampg)),
       data = data_pgs(i.id, i.doampg),
       index_size = data_pgs(i.id, i.ioampg),
		 segname = s.name,
		 indid
into   #indexspace
from   sysobjects o, sysindexes i, syssegments s
where  i.id = o.id
and    (o.type = "U" or o.name = "syslogs")
and    s.segment = i.segment
and	 isnull(@objname,o.name)=o.name

update #indexspace
set    name=user_name(owner_id)+'.'+name
where  owner_id>1

update #indexspace 
set    row_cnt=( select i2.row_cnt from #indexspace i2
					where i1.name = i2.name
					and   i1.owner_id = i2.owner_id
					and   i2.indid<=1 )
from   #indexspace i1
where  indid>1

update #indexspace
set    name=name+'.'+idxname
where  indid!=0

update #indexspace
set    row_cnt=-1
where  row_cnt>99999999

print "Data Level (Index Type 0 or 1)"
select 
	convert(char(22),name)                       "Name", 
   convert(char(8),row_cnt)     					   "Rows",
   convert(char(16),rtrim(convert(char(30),(reserved*@pagesize)/1024))+"/"+
   rtrim(convert(char(30),(data*@pagesize)/1024))+"/"+
   rtrim(convert(char(30),(index_size*@pagesize)/1024))) "Used/Data/Idx KB",
	str((row_cnt*1024)/(convert(float,data+index_size)*@pagesize),6,2) "Rows/KB",
	convert(char(12),segname) "Segment"
from #indexspace
where indid<=1
order by name

print ""
print "Non Clustered Indexes"
select 
	convert(char(22),name)           "Name", 
   convert(char(8),row_cnt)       					   "Rows",
   convert(char(16),rtrim(convert(char(30),(reserved*@pagesize)/1024))+"/"+
   rtrim(convert(char(30),(data*@pagesize)/1024))+"/"+
   rtrim(convert(char(30),(index_size*@pagesize)/1024))) "Used/Data/Idx KB",
	str((row_cnt*1024)/(convert(float,data+index_size)*@pagesize),6,2) "Rows/KB",
	convert(char(12),segname) "Segment"
from #indexspace
where indid>1
order by name

drop table #indexspace

return(0)

END

go

GRANT EXECUTE ON sp__indexspace TO public
go

