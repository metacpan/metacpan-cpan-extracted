/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

/******************************************************************************
** Name        : sp__helprule.sp
******************************************************************************/

if exists ( select * from sysobjects
           where  name = "sp__helprule"
           and    type = "P" )
   drop proc sp__helprule
go
create proc sp__helprule( 
                @objname        varchar(92) = NULL,
					 @dont_format char(1) = null
				)
as 
begin

	select rule_name = name,
				uid,
				times_used = ( select count(*) from syscolumns
										where domain=o.id ),
				value = ( select text from syscomments c where c.id=o.id and colid=1)
	  into   #dflts
	  from   sysobjects o
	  where  name like "%"+@objname+"%"
	  and    type = "R"
	  order  by name

if exists (select * from sysobjects where name=@objname and type='R' )
		  delete #dflts
		  where rule_name!= @objname

if not exists ( select * from #dflts )
begin
	if @objname is not null
		print "Rule Not Found"
	else
		print "No Rules In Database"
	return
end

update #dflts
set  	 rule_name = user_name(uid)+'.'+rule_name
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

select substring(rule_name,1,20) "Rule Name" ,
		 convert(char(10),times_used) "Times Used",
		 convert(char(46),value) 		"Definition"
from #dflts
order by rule_name
		
drop table #dflts

end

go

grant execute on sp__helprule  to public
go
