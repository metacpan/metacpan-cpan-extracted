/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__helptrigger.sp
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__helptrigger"
           and    type = "P")
   drop proc sp__helptrigger
go

create proc sp__helptrigger( @objname varchar(92) = NULL,
	@dont_format char(1) = null
	)
AS 
BEGIN

select 
	 name,
	 uid,
	 owner = convert(char(15),user_name(uid)),
	 crdate,
	 ins_cnt = convert(char(7),( select count(*) from sysobjects where instrig=*o.id )),
	 del_cnt = convert(char(7),( select count(*) from sysobjects where deltrig=*o.id )),
	 upd_cnt = convert(char(7),( select count(*) from sysobjects where updtrig=*o.id ))
into   #trigs
from   sysobjects o
where  name like "%"+@objname+"%"
and    type = "TR"
order  by name

if exists (select * from sysobjects where name=@objname and type='D' )
		  delete #trigs
		  where name!= @objname

if not exists ( select * from #trigs )
begin
	if @objname is not null
		print "Trigger Not Found"
	else
		print "No Triggers In Database"
	return
end

update #trigs
set  	 name = user_name(uid)+'.'+name
where  uid!=1

select 
	 name 	"Trigger Name",
	 convert(char(2),crdate,6)
						+substring(convert(char(9),crdate,6),4,3)
						+substring(convert(char(9),crdate,6),8,2) "Cr Date",
	 ins_cnt "Ins Cnt",
	 del_cnt "Del Cnt",
	 upd_cnt "Upd Cnt"
from #trigs
END
go

grant execute on sp__helptrigger  to public
go
