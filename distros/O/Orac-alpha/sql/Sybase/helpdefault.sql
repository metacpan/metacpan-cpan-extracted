/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__helpdefault
**
******************************************************************************/

:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__helpdefault"
           and    type = "P")
   drop proc sp__helpdefault

go

create proc sp__helpdefault( 
                @objname        varchar(92) = NULL,
						 @dont_format char(1) = null
						 )
as 
begin

	select default_name = name,
				uid,
				times_used = ( select count(*) from syscolumns
										where cdefault=o.id ),
				value = ( select text from syscomments c where c.id=o.id and colid=1)
	  into   #dflts
	  from   sysobjects o
	  where  name like "%"+@objname+"%"
	  and    type = "D"
	  order  by name

if exists (select * from sysobjects where name=@objname and type='D' )
		  delete #dflts
		  where default_name!= @objname

if not exists ( select * from #dflts )
begin
	if @objname is not null
		print "Default Not Found"
	else
		print "No Defaults In Database"
	return
end

update #dflts
set  	 default_name = user_name(uid)+'.'+default_name
where  uid!=1

/* delete everything until first as */
/* get rid of newlines from definition */
update #dflts
set    value = lower(value)

while 1=1
begin
	update #dflts
	set    value=stuff(value,charindex(char(10),value),1,' ')
	where  charindex(char(10),value)!=0

	if @@rowcount = 0
	begin
		  update #dflts
		  set    value=stuff(value,charindex(char(14),value),1,' ')
		  where  charindex(char(14),value)!=0
		  if @@rowcount = 0 break
	end
end

/* there should be a string ' as ' at this stage */
update #dflts
set    value = substring(value,patindex('% as %',value)+4,120)

select substring(default_name,1,20) "Default Name" ,
		 convert(char(10),times_used) "Times Used",
		 convert(char(46),value) 		"Definition"
from #dflts
order by default_name
		
drop table #dflts
END

go

grant execute on sp__helpdefault  to public
go
