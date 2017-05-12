/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	read_write					
|*									
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__read_write")
begin
    drop proc sp__read_write
end
go

create procedure sp__read_write  ( @objname char(30)=NULL,
	@dont_format char(1) = null
	)
as
 set nocount on
 declare @oid int
 declare @type char(2)

if @objname is null
   select @oid = null
else
   select @oid = object_id(@objname)

create table #tmp (
	Tblname		char(30) not null,
	SelInto		int  not null,
	NumReads	int  not null,
	NumWrites	int  not null,
	ReadWrite	int  not null,
	id		int  not null,
	num_rows	int  not null
)

if @oid is null
begin

 select @type=null

 /* Make sure that both ends are null */
 insert #tmp
 select distinct 
    Tblname=o2.name,
    SelInto=sum(convert(smallint,selall )),
    NumReads=sum(convert(smallint,readobj )),
    NumWrites=sum(convert(smallint,resultobj )),
    ReadWrite=sum((convert(smallint,readobj)+convert(smallint,resultobj))&2)/2,
    o2.id, num_rows=0
 from   sysdepends d,sysobjects o,sysobjects o2
 where 	d.id=o.id
 and  	d.depid=o2.id
 and  	o2.type='U'
 and	o.uid=1 and o2.uid=1
 group by d.depid 
 having	d.id=o.id
 and  	d.depid=o2.id
 and  	o2.type='U'
 and	o.uid=1 and o2.uid=1

end
else
begin

 select @type=type
 from sysobjects where id=@oid

 if @type in ('S','U','V')
 insert #tmp
  select distinct
	Tblname=object_name(d.id),
	SelInto=convert(smallint,selall ),
	NumReads=convert(smallint,readobj ),
	NumWrites=convert(smallint,resultobj ),
	ReadWrite=((convert(smallint,readobj)+convert(smallint,resultobj))&2) / 2 ,
	d.id,
	num_rows=0 
	from   sysdepends d
	where   d.depid = @oid
 else
 /* If a procedure, just get tables */
 insert #tmp
 select distinct 
    Tblname=o2.name,
    SelInto=sum(convert(smallint,selall )),
    NumReads=sum(convert(smallint,readobj )),
    NumWrites=sum(convert(smallint,resultobj )),
    ReadWrite=sum((convert(smallint,readobj)+convert(smallint,resultobj)+1)&2)/2,
    o2.id, num_rows=0
 from   sysdepends d,sysobjects o2
 where 	o2.uid = 1
 and  	d.depid=o2.id
 and  	o2.type='U'
 and	   o2.uid=1
 and    d.id = @oid
 group by d.depid 
 having	d.depid=o2.id
 and  	o2.type='U'
 and	   o2.uid=1
 and    o2.uid = 1
 and    d.id = @oid

end

update #tmp
set    num_rows=( select sum( rowcnt(doampg) )
 			from   sysindexes i
 			where  i.id=#tmp.id )

select Tblname,
    	Sel  =  convert(char(5),SelInto),
    	Reads=  convert(char(5),NumReads),
    	Writes= convert(char(5),NumWrites),
    	"R&W" = convert(char(5),ReadWrite),
    	num_rows
 from #tmp

 return 
go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__read_write to public
go
