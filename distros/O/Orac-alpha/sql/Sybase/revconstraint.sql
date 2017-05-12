:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp_revconstraint")
begin
    drop proc sp_revconstraint
end
go


create proc sp_revconstraint(@object char(30)=NULL,
	@dont_format char(1) = null
	)
as 
begin

declare @type   smallint                /* the object type */
declare @nl     char    /* RV added */

select @nl = char(10)   /* RV added */

select owner      = user_name(o.uid),
       name       = o.name,
       index_name = i.name,
       indexid    = i.indid,
	status	   = status,
	status2	   = status2,  /* RV added */
	createstmt = convert(varchar(127),"N.A."),
	keylist    = convert(varchar(127),"N.A."),
	endingstmt = convert(varchar(127),""),
	segment	   = segment
into   #indexlist
from   sysobjects o, sysindexes i
where  i.id   = o.id
and    o.type = "U"
and	 isnull(@object,o.name)=o.name
and	 indid > 0
and	 indid < 255  
and  status2 & 2 = 2

if @@rowcount = 0
begin
	if @object is null
	begin
		select convert(varchar(255),"No constraints found in Current Database")
	end
	return
end

/* delete multiple rows */
delete #indexlist
from   #indexlist a, #indexlist b
where  a.indexid = 0
and    b.indexid != 0
and    a.name = b.name

update #indexlist
set    createstmt = 'ALTER TABLE ' + rtrim(owner) + '.' + rtrim(name) + 
                    ' ADD CONSTRAINT ' + rtrim(index_name) 
where  status2 & 2 = 2

update #indexlist
set    createstmt = rtrim(createstmt)+' UNIQUE'
where  status & 2 = 2

update #indexlist
set    createstmt = rtrim(createstmt)+' CLUSTERED'
where  indexid = 1

update #indexlist
set    createstmt = rtrim(createstmt)+' NONCLUSTERED'
where  indexid != 1

update #indexlist
set    createstmt = rtrim(createstmt) + ' ('
where  status2 & 2 = 2

declare @count int
select  @count=1

while ( @count < 17 )	/* 16 appears to be the max number of index cols */
begin

	if @count=1
		update #indexlist
		set    keylist=index_col(owner+"."+name,indexid,@count)
		where  index_col(owner+"."+name,indexid,@count) is not null
   else
		update #indexlist
		set    keylist=rtrim(keylist)+","+index_col(owner+"."+name,indexid,@count)
		where  index_col(owner+"."+name,indexid,@count) is not null

	if @@rowcount=0	break

	select @count=@count+1
end

/* add on segment clause if other than default */
update #indexlist
set i.endingstmt=" ON '"+rtrim(s.name)+"' "+rtrim(i.endingstmt)
from  #indexlist i,syssegments s
where s.segment = i.segment
and s.name <> "default"

update #indexlist
set endingstmt=" WITH IGNORE_DUP_KEY "+rtrim(endingstmt)
where status&1 = 1

update #indexlist
set endingstmt=" WITH IGNORE_DUP_ROW "+rtrim(endingstmt)
where status&4 = 4

update #indexlist
set endingstmt=" WITH ALLOW_DUP_ROW "+rtrim(endingstmt)
where status&64 = 64

update #indexlist
set keylist="", endingstmt=""
where segment = -1

update #indexlist
set segment=1, endingstmt=") "+rtrim(endingstmt)
where segment != -1

select convert(varchar(255),createstmt+keylist+endingstmt)
from #indexlist
order by segment,owner,name,indexid

if @@rowcount = 0
begin
        if @object is null
        begin
                select convert(varchar(255),"No Constrains found for this object")
        end
        return
end

return(0)

end
                       
go
grant exec on sp_revconstraint to public
go
 
