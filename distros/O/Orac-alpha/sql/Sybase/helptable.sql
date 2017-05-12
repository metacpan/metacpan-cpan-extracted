/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__helptable.sp
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__helptable"
           and    type = "P")
   drop proc sp__helptable

go

/* If @do_system_tables = 'S' also show system stuff */
create proc sp__helptable( @objname varchar(92) = NULL, @do_system_tables char(1)=' ', @dont_format char(1)=null)
AS 
BEGIN

declare @pgsz int
select  @pgsz = low/1024 from master..spt_values 
where   number=1 and type='E'

/* If you want to see a specific system objects */
/* if @objname is not null and @do_system_tables is null
	select @do_system_tables=type from sysobjects where name=@objname */

if @do_system_tables != ' ' or @objname is not null
	select @do_system_tables='S'

select name = substring(o.name, 1, 24),
       owner_id = o.uid,
		 indid,
		 crdate,
       row_cnt = rowcnt(i.doampg),
       reserved = (reserved_pgs(i.id, i.doampg) +
              	   reserved_pgs(i.id, i.ioampg)),
       data = data_pgs(i.id, i.doampg),
       index_size = data_pgs(i.id, i.ioampg),
       unused =  ((reserved_pgs(i.id, i.doampg)
                  + reserved_pgs(i.id, i.ioampg))
                  - (data_pgs(i.id, i.doampg) 
                  + data_pgs(i.id, i.ioampg))),
		 segname = s.name
into   #tableinfo
from   sysobjects o, sysindexes i, syssegments s
where  i.id = o.id
and    (o.type in ("U",@do_system_tables) or o.name = "syslogs")
and    s.segment = i.segment
and	 isnull(@objname,o.name)=o.name

update #tableinfo
set    name=user_name(owner_id)+'.'+name
where  owner_id>1

select distinct name, 
		crdate,
      row_cnt = sum(row_cnt),
      reserved = sum(reserved)*@pgsz,
      data = sum(data)*@pgsz ,
      indexes = sum(index_size)*@pgsz,
      unused = sum(unused)*@pgsz,
		segname="                   ",
		rowsper=convert(int,0),
		str_row_cnt="        ",
		str_reserved="      ",
		str_used="      "

into #sum_info
from #tableinfo
group by name
order by name

update #sum_info
set  rowsper=(row_cnt/convert(float,data+indexes))*100
where data+indexes > 0

update #sum_info
set segname=""

select distinct name,segname
into #segs
from #tableinfo

declare @i int
select  @i = 0
while @i < 15
begin
	update #sum_info
	set 	 segname = rtrim(i.segname) + rtrim(t.segname) +","
	from   #tableinfo t, #sum_info i, #segs s
	where  t.name = i.name
	and    t.indid=@i
	and	 s.name = t.name
	and	 s.name = i.name
	and	 s.segname=t.segname

	delete #segs
	from   #tableinfo t, #segs s
	where  t.indid=@i
	and	 s.name = t.name
	and	 s.segname=t.segname

	if @i>3 and @@rowcount=0 break
	
	select @i = @i+1
end

update #sum_info
set segname = substring(segname,1,datalength(segname)-1)

if @dont_format is null
begin
	/* OK - HANDLE *HUGE* TABLES NOW */
	declare @maxrows int
	select @maxrows = max(row_cnt) from #sum_info
	if @maxrows>=99999999
	begin
			/* Copy into temporary string variables */
			update #sum_info
			set
				str_row_cnt=  convert(char(8),row_cnt) ,
				str_reserved= convert(char(6),reserved) ,
				str_used=     convert(char(6),data+indexes) 
			where row_cnt<=99999999
			and   reserved<999999
			and   data+indexes<999999

			/* Now the big ones */
			update #sum_info
			set
				str_row_cnt=  rtrim(convert(char(7),row_cnt/1000))+"M" ,
				str_reserved= rtrim(convert(char(5),reserved/1000 ))+"M",
				str_used=     rtrim(convert(char(5),(data+indexes)/1000))+"M" 
			where row_cnt>=99999999
			or   reserved>=999999
			or   data+indexes>=999999

			select   convert(char(23),name) "Table Name", 
         			str_row_cnt "Rows",
         			str_reserved "Res KB",
						str_used "Usd KB",
						str(convert(float,rowsper)/100.0,6,2) "Rows/KB",
						convert(char(13),segname) "Segment",
						convert(char(2),crdate,6)
									+substring(convert(char(9),crdate,6),4,3)
									+substring(convert(char(9),crdate,6),8,2) "Cr Date"
			from #sum_info
			order by name
	end
	else
	begin
 		update #sum_info set row_cnt = -1  
			where char_length(rtrim(ltrim(convert(char(20),row_cnt)))) > 8
 		update #sum_info set reserved = -1  
			where char_length(rtrim(ltrim(convert(char(20),reserved))))>6
 		update #sum_info set data=data+indexes
 		update #sum_info set data = -1  
			where char_length(rtrim(ltrim(convert(char(20),data))))>6
			
		select   convert(char(23),name) "Table Name", 
         convert(char(8),row_cnt) "Rows",
         convert(char(6),reserved) "Res KB",
			convert(char(6),data) "Usd KB",
			str(convert(float,rowsper)/100.0,6,2) "Rows/KB",
			convert(char(13),segname) "Segment",
			convert(char(2),crdate,6)
						+substring(convert(char(9),crdate,6),4,3)
						+substring(convert(char(9),crdate,6),8,2) "Cr Date"
		from #sum_info
		order by name
	end
end
else
	select   
			name "Table Name", 
         row_cnt "Rows",
         reserved "Res KB",
			data+indexes "Usd KB",
			str(convert(float,rowsper)/100.0,6,2) "Rows/KB",
			segname "Segment",
			convert(char(2),crdate,6)
						+substring(convert(char(9),crdate,6),4,3)
						+substring(convert(char(9),crdate,6),8,2) "Cr Date"
	from #sum_info
	order by name

drop table #sum_info
drop table #tableinfo

return(0)

END

go

grant execute on sp__helptable  TO public
go
