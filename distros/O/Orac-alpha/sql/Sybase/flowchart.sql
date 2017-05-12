/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	flowchart					
		A complete rewrite of my pass #1 below
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__flowchart")
begin
    drop proc sp__flowchart
end
go

create procedure sp__flowchart (@objname char(30)=NULL, @dont_format char(1)=NULL)
as

set nocount on

declare @cnt int

create table #tmp
(
	 calling_id  int null
	 ,called_id  int null
)
	 
/* Calling, Called */
	insert   #tmp
	select	distinct calling_id=o.id,called_id=o2.id
	from   	sysdepends d,sysobjects o,sysobjects o2
	where 	d.id=o.id
	and  		d.depid=o2.id
	and  		o2.type='P'
	and  		o.type='P'

select @cnt=@@rowcount
if @cnt=0 and @dont_format is null
begin
	print "Error - No Procedure Dependencies Found"
	return
end

create table #output
(
	 level1  int null
	,level2  int null
	,level3  int null
	,level4  int null
	,level5  int null
	,level6  int null
)

if @cnt>0
begin

if @objname is null
	insert   #output
	select	a.calling_id,a.called_id,NULL,NULL,NULL,NULL
	from   	#tmp a
else
	insert   #output
	select	a.calling_id,a.called_id,NULL,NULL,NULL,NULL
	from   	#tmp a
	where	   calling_id=object_id(@objname)

   select @cnt=@@rowcount
end

if @cnt>0
begin

	insert   #output
	select	a.level1,a.level2,b.called_id,NULL,NULL,NULL
	from   	#output a,#tmp b
	where 	a.level2 = b.calling_id
	and	   a.level2 is not null

   select @cnt=@@rowcount
end

if @cnt>0
begin

	insert   #output
	select	a.level1,a.level2,a.level3,b.called_id,NULL,NULL
	from   	#output a,#tmp b
	where 	a.level3 = b.calling_id
	and	   a.level3 is not null

   select @cnt=@@rowcount
end

if @cnt>0 and @dont_format is not null
begin

	insert   #output
	select	a.level1,a.level2,a.level3,a.level4,b.called_id,NULL
	from   	#output a,#tmp b
	where 	a.level4 = b.calling_id
	and	   a.level4 is not null

   select @cnt=@@rowcount
end

if @cnt>0 and @dont_format is not null
begin

	insert   #output
	select	a.level1,a.level2,a.level3,a.level4,a.level5,b.called_id
	from   	#output a,#tmp b
	where 	a.level5 = b.calling_id
	and	   a.level5 is not null

   select @cnt=@@rowcount
end

if @dont_format is null
select "level 1"=substring(isnull(object_name(level1),""),1,18),
		 "level 2"=substring(isnull(object_name(level2),""),1,18),
		 "level 3"=substring(isnull(object_name(level3),""),1,18),
		 "level 4"=substring(isnull(object_name(level4),""),1,18)
from #output
order by object_name(level1),object_name(level2),object_name(level3),object_name(level4)
else
select "level 1"=object_name(level1),
		 "level 2"=object_name(level2),
		 "level 3"=object_name(level3),
		 "level 4"=object_name(level4),
		 "level 5"=object_name(level5),
		 "level 6"=object_name(level6)
from #output
order by object_name(level1),object_name(level2),object_name(level3),object_name(level4),object_name(level5),object_name(level6)

drop table #output
go

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__flowchart to public
go

/* THE FOLLOWING STUFF IS A PARSER - I HAVE KEPT IT FOR HISTORICAL REASONS
	ONLY - ED */

exit

set nocount on
declare @count int

/* Get List Of Procs */
select name
into   #proclist 
from   sysobjects where type='P'

select @count =1 

select id,text,loc=charindex('exec',text),colid=convert(int,colid)
into 	 #rawtext
from   syscomments
where  lower(text) like "%exec%"

/* first pass - rows with the word exec */
if @objname is not null
		  delete #rawtext where id!=object_id(@objname)

update #rawtext
set    loc=charindex('EXEC',text)
where  loc=0

update #rawtext set text=lower(text)

select *,x=300,y=300,z=300,num=0 into #txt from #rawtext where 1=2

/* now duplicate the rows if there are more exec lines */
/* Algorithm */
/* copy from text to txt */
/* update text */
/* update indexes (loc) */
/* increment counter */
while 1=1
begin
	insert #txt
	select id,text,loc,colid,x=300,y=300,z=300,num=@count
	from   #rawtext

	if @@rowcount = 0 break

	update #rawtext
	set text = substring(text,loc+2,255)

	update #rawtext
	set loc = charindex('exec',text)

	delete #rawtext where loc=0

	select @count = @count + 1
end

/* at this stage we have a nicely split row */

/* now rotate the rows */
update #txt
set    text=rtrim(substring(t1.text,loc,255))+substring(t2.text,1,60),loc=1
from   #txt t1,syscomments t2
where  datalength(t1.text)-loc < 50
and    t1.id=t2.id
and    t1.colid + 1 = t2.colid

/* delete any words that contain exec... but are not exec statements */
delete #txt where text like "%exec[^u 	]%"
delete #txt where text like "%execute[^ 	]%"
delete #txt where text like "%execu[^t][^e]%"
delete #txt where text like "%execu[^t][^e][^ 	]%"

/* For those lines you just word wrapped you must worry if the space */
/* was truncated between exec and the actual proc */
/* 
update #txt
set    text=substring(text,charindex('exec',text)+4,90)
where  loc>=250

update #txt
set text=substring(text,2,90)
where text like " %"
and   loc>=250
*/

/* get rid of exec lines */
update #txt set text=substring(text,loc+5,255)

/* get rid of executes too */
update #txt
set 	 text=substring(text,3,255)
where  text like "te %"

/* Alright now drop after space */
/* space, tab, CR can occur in any order */
update #txt set loc= 300, text=ltrim(text)

/* delete anything that cant be a proc */
delete #txt where text not like "[a-z]%"

update #txt set loc=charindex(' ',text),
					 x=charindex( '	',text),
					 y=charindex(char(10),text),
					 z=charindex(char(15),text)

update #txt set loc=300 where loc=0
update #txt set loc=x where x<loc and x!=0
update #txt set loc=y where y<loc and y!=0
update #txt set loc=z where z<loc and z!=0

delete #txt where loc=300

update #txt set text=rtrim(substring(text,1,loc-1))

/* DEBUG */
/*
select loc,x,y,z,colid,
	ascii(substring(text,loc,1)), datalength(text),
	substring('/'+text+'/',1,30)
from #txt
*/

/* now a filter for procs */
update #txt set loc=0
update #txt set loc=1 where text like "%..%"
update #txt set loc=1 where text like "%.dbo.%"
update #txt set loc=1 where text like "%dbo.%"
update #txt set loc=1 where text in ( select name from #proclist )
delete #txt where loc=0

select object_name(id),substring(text,1,46)
from #txt
order by object_name(id),colid,num

drop   table #txt
drop   table #rawtext
drop   table #proclist

return (0)

/* NOTE THAT THERE IS NO GO HERE - INTENTIONALLY */
