/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__helpview.sp
**
******************************************************************************/
:r database
go
:r dumpdb
go

IF EXISTS (SELECT * FROM sysobjects
           WHERE  name = "sp__helpview"
           AND    type = "P")
   DROP PROC sp__helpview

go

create proc sp__helpview( @objname char(30) = NULL,
	@dont_format char(1) = null
	)
AS 
begin

	select view_name = name,
				uid,
				crdate,
				value = ( select text from syscomments c where c.id=o.id and colid=1 )
	  into   #helpview
	  from   sysobjects o
	  where  name like "%"+@objname+"%"
	  and    type = "V"
	  order  by name

if exists (select * from sysobjects where name=@objname and type='V' )
		  delete #helpview
		  where view_name!= @objname

if not exists ( select * from #helpview )
begin
	if @objname is not null
		print "View Not Found"
	else
		print "No Views In Database"
	return
end

update #helpview
set  	 view_name = user_name(uid)+'.'+view_name
where  uid!=1

/* delete everything until first as */
/* get rid of newlines from definition */
update #helpview
set    value = lower(value)

while 1=1
begin
	update #helpview
	set    value=stuff(value,charindex(char(10),value),1,' ')
	where  charindex(char(10),value)!=0

	if @@rowcount = 0
	begin
		  update #helpview
		  set    value=stuff(value,charindex(char(14),value),1,' ')
		  where  charindex(char(14),value)!=0
		  if @@rowcount = 0 break
	end
end

/* the from clause should be ' from ' at this stage */
update #helpview
set    value = substring(value,patindex('% from %',value)+6,120)

update #helpview
set    value = substring(value,1,patindex('% where %',value))
where substring(value,1,patindex('% where %',value)) is not null

select substring(view_name,1,20)     "View Name" ,
		convert(char(2),crdate,6)
						+substring(convert(char(9),crdate,6),4,3)
						+substring(convert(char(9),crdate,6),8,2) "Cr Date",
		 convert(char(45),value) 		 "Tables Used"
from #helpview
order by view_name
		
drop table #helpview
end
go

GRANT EXECUTE ON sp__helpview  TO public
go
