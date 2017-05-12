
/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__checkkey
**
** Created By  : Ed Barlow
**
******************************************************************************/

:r database
go
:r dumpdb
go

IF EXISTS (SELECT * FROM sysobjects
           WHERE  name = "sp__checkkey"
           AND    type = "P")
   DROP PROC sp__checkkey

go

create proc sp__checkkey(@object varchar(30)=NULL,
	@dont_format char(1) = null
	)
as 
begin

/* Get Foreign Keys */
select k.id,nm=object_name(k.id),depid,depnm=object_name(depid),k.keycnt,
	joinclause=convert(varchar(255),""), selectkey=convert(varchar(255),""),
	key1,key2,key3,key4,key5,key6,key7,key8,
	depkey1,depkey2,depkey3,depkey4,depkey5,depkey6,depkey7,depkey8
into  #keylist
from	syskeys k, sysobjects o
where depid is not null
and	k.type=2
and	k.id=o.id
and	o.type='U'
and	isnull(@object,object_name(o.id))=object_name(o.id)

update #keylist
set    joinclause="p."+col_name(k.id,key1)+"=d."+col_name(k.depid,depkey1),
       selectkey=col_name(k.id, key1)
from   #keylist k
where  k.keycnt>=1

update #keylist
set    joinclause=joinclause+" and p."+col_name(k.id,key2)+"=d."+col_name(k.depid,depkey2),
       selectkey=selectkey+", "+col_name(k.id, key2)
from #keylist k
where k.keycnt>=2

update #keylist
set    joinclause=joinclause+" and p."+col_name(k.id,key3)+"=d."+col_name(k.depid,depkey3),
       selectkey=selectkey+", "+col_name(k.id, key3)
from #keylist k
where k.keycnt>=3

update #keylist
set    joinclause=joinclause+" and p."+col_name(k.id,key4)+"=d."+col_name(k.depid,depkey4),
       selectkey=selectkey+", "+col_name(k.id, key4)
from #keylist k
where k.keycnt>=4

update #keylist
set    joinclause=joinclause+" and p."+col_name(k.id,key5)+"=d."+col_name(k.depid,depkey5),
       selectkey=selectkey+", "+col_name(k.id, key5)
from #keylist k
where k.keycnt>=5

update #keylist
set    joinclause=joinclause+" and p."+col_name(k.id,key6)+"=d."+col_name(k.depid,depkey6),
       selectkey=selectkey+", p."+col_name(k.id, key6)
from #keylist k
where k.keycnt>=6

update #keylist
set    joinclause=joinclause+" and p."+col_name(k.id,key7)+"=d."+col_name(k.depid,depkey7),
       selectkey=selectkey+", p."+col_name(k.id, key7)
from #keylist k
where k.keycnt>=7

update #keylist
set    joinclause=joinclause+" and p."+col_name(k.id,key8)+"=d."+col_name(k.depid,depkey8),
       selectkey=selectkey+", p."+col_name(k.id, key8)
from #keylist k
where k.keycnt>=8

declare @prirows int, @secrows int
declare @txt varchar(255)
set rowcount 1
while 1=1 
begin
	select @prirows=id, @secrows=depid
	from   #keylist


	if @@rowcount=0 break

/* select selectkey into #tmp from primary */
/* delete #tmp from #tmp t,secontary sec where joinclause */
/* print  #tmp */
	print  "declare @cnt int"
	print  "set nocount on"

	select @txt="select "+selectkey+" into #tmp from "+nm
	from   #keylist where id=@prirows and depid=@secrows
	print  @txt
	
	select @txt="delete #tmp from #tmp p,"+depnm+" d where "+joinclause
	from   #keylist where id=@prirows and depid=@secrows
	print  @txt

	print  "if exists ( select * from #tmp )"
	print  "begin"

	print  "select @cnt=count(*) from #tmp"
	print  "if @cnt>=100"
	select @txt=" print 'first 100 keys in "+nm+" w/o data in "+depnm+"'"
	from   #keylist where id=@prirows and depid=@secrows
	print  @txt
	print  "else"
	select @txt=" print 'distinct keys in "+nm+" w/o data in "+depnm+"'"
	from   #keylist where id=@prirows and depid=@secrows
	print  @txt
	print  " set rowcount 100"
	print  " select distinct * from #tmp"
	print  " set rowcount 0"
	print  "end"
	print  "drop table #tmp"
	print  "go"
	print  ""

   delete #keylist
	where  @prirows=id and @secrows=depid
end


return(0)

end

go

grant execute on sp__checkkey to public
go
