/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revdb")
begin
    drop proc sp__revdb
end
go

create procedure sp__revdb ( @dont_format char(1) = null)
as

declare @numpgsmb float		/* Number of Pages per Megabytes */
declare @curdbid    int,@msg char(127), @name char(30),@size char(30)
declare @count int , @cnt int

create table #tmp 
(
	cnt int,
	txt char(127)
)

select @numpgsmb = (1048576. / v.low), @cnt=1
from master.dbo.spt_values v
where v.number = 1 and v.type = "E"

select @curdbid = min(dbid)
from master.dbo.sysdatabases 

select  	u.dbid,
		  	name = dv.name,
		  	size = convert(char(20),u.size / 512),
		  	segmap = u.segmap
into  	#devlayout
from  	master.dbo.sysusages u, master.dbo.sysdevices dv
where    dv.low <= size + vstart
			and dv.high >= size + vstart - 1
			and dv.status & 2 = 2
group by dv.name
order by u.dbid,u.segmap

while @curdbid is not null
begin

set nocount on
	/* if @curdbid>3 */
	begin
		set rowcount 1

		select @count=0
		select @msg="XXX"

		/* Data Space */
	   while @msg is not null
		begin
			select @name=name,@size=size
			from	 #devlayout
			where  dbid=@curdbid
			and    segmap & 2 = 2
		   if @@rowcount=0 break

			if @count=0
			   select @msg="Create Database "+db_name(@curdbid)+" on "+rtrim(@name)+"="+rtrim(@size),@count=1
		   else
			   select @msg="    ,"+rtrim(@name)+"="+rtrim(@size)

		   insert #tmp select  @cnt, @msg
			select @cnt = @cnt + 1

			delete  #devlayout
			where   dbid=@curdbid
			and     name=@name
			and	  size=@size
			and     segmap & 2 = 2
		   if @@rowcount=0 break
		end

		select @count=2

		/* Log Space */
	   while @msg is not null
		begin
			select @name=name,@size=size
			from	 #devlayout
			where  dbid=@curdbid
		   if @@rowcount=0 break

			if @count=2
			   select @msg="     log on "+rtrim(@name)+"="+rtrim(@size),@count=3
		   else
			   select @msg="    ,"+rtrim(@name)+"="+rtrim(@size)

		   insert #tmp select  @cnt, @msg
			select @cnt = @cnt + 1

			delete  #devlayout
			where   dbid=@curdbid
			and     name=@name
			and	  size=@size
		   if @@rowcount=0 break
		end
		set rowcount 0
	end

		set 		rowcount 1

		select 	@curdbid = min(dbid)
		from 		master.dbo.sysdatabases 
		where 	dbid>@curdbid

		if @@rowcount = 0 	/* Seems to abort on the null @curdb not here??? */
		begin
			break
		end

		set rowcount 0
end

declare @maxlen int
select @maxlen=max(char_length(rtrim(txt))) from #tmp

if @maxlen<60
	select substring(txt,1,60)
	from #tmp
	order by cnt
else if @maxlen<80
	select substring(txt,1,80)
	from #tmp
	order by cnt
else if @maxlen<120
	select substring(txt,1,120)
	from #tmp
	order by cnt
else
	select txt
	from #tmp
	order by cnt

return (0)
go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__revdb to public
go
