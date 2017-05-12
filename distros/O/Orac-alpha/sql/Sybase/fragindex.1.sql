create proc sp__fragindex(@object char(30)=NULL,
	 	 	  @dont_format int = null
	)
as 
begin
declare @type   smallint                /* the object type */
declare @nl     char 
declare @ind_column     char(30)    /* AS added */
declare @indid int                      /* the index id of an index */
declare @Num_refer int         /* the number of foreign references */
select @nl = char(10)  

/*
**  Check to see that the object names are local to the current database.
*/
if @object like "%.%.%" and
        substring(@object, 1, charindex(".", @object) - 1) != db_name()
begin
        /* 17460, "Object must be in the current database." */
        RAISERROR 17460
        return (1)
end

/*
**  Check to see the the table exists 
*/
if not exists (select id
                from sysobjects
                        where id = object_id(@object))
/*
**  Table doesn't exist so return.
*/
begin
        /* 17461, "Object does not exist in this database." */
        RAISERROR 17461
        return (1)
end

/*
**  See if the object has any indexes.
**  Since there may be more than one entry in sysindexes for the object,
**  this select will set @indid to the index id of the first index.
*/
select @indid = min(indid)
        from sysindexes
                where id = object_id(@object)
                        and indid > 0
                        and indid < 255

/*
**  If no indexes, return.
*/
if @indid is NULL
begin
        /* User wants us to automatically pick a column to build an index on */
        if @dont_format = 1
        begin
                select @ind_column=name from syscolumns where id = object_id(@object) and colid = 1
        end
        select "DROP INDEX  " + rtrim(@object) + ".__ORAC_TEST__"
        select "CREATE CLUSTERED INDEX __ORAC_TEST__ ON " + rtrim(@object) + " (" + rtrim(@ind_column) +") WITH ALLOW_DUP_ROW, FILLFACTOR=80, SORTED_DATA"
        return
end


        select @Num_refer =
                (select count(*) from sysreferences 
                        where reftabid = obj.id and pmrydbname is NULL)
                +
                (select count(*) from sysreferences 
                        where tableid = obj.id and frgndbname is NULL 
                        and not (reftabid = obj.id and pmrydbname is NULL))

        from sysobjects obj
        where ( obj.sysstat2 & 3  != 0 ) and ( obj.type = "U" ) and (obj.id = object_id(@object)) 

/* There are foreign keys to the constraint, do not even bother */
if @Num_refer > 0
begin
        return
end
 

select  owner      = user_name(o.uid),
        name       = o.name,
        index_name = i.name,
        indexid    = i.indid,
	status	   = status,
	status2	   = status2,  
        createstmt = convert(varchar(127),"N.A."),
	keylist    = convert(varchar(127),"N.A."),
	endingstmt = convert(varchar(127),@nl),
	segment	   = segment
into   #indexlist
from   sysobjects o, sysindexes i
where  i.id   = o.id
and    o.type = "U"
and	 id = object_id(@object)
and	 indid > 0
and	 indid < 255  

if @@rowcount = 0
begin
	if @object is null
	begin
		select convert(varchar(255),"No Indexes found in Current Database")
	end
	return
end

/* delete multiple rows */
delete #indexlist
from   #indexlist a, #indexlist b
where  a.indexid = 0
and    b.indexid != 0
and    a.name = b.name

/* delete all nonclustered indexes */
delete #indexlist
where  indexid != 1

/*  
 handle cases where indexes were created as 'real' indexes
 also handle cases where indexes were defined as constraints
*/
update #indexlist
set    createstmt='CREATE'
where  status2 & 2 = 0

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
set    createstmt = rtrim(createstmt)+ ' INDEX '+rtrim(index_name) 
                    + " ON "+rtrim(owner)+"."+rtrim(name)+' ('
where  status2 & 2 = 0
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
set endingstmt=" WITH FILLFACTOR=80, SORTED_DATA "+rtrim(endingstmt)
where status2 & 2 = 0

update #indexlist
set i.endingstmt=" ON '"+rtrim(s.name)+"' "+rtrim(i.endingstmt)
from  #indexlist i,syssegments s
where s.segment = i.segment
and s.name <> "default"
update #indexlist
set endingstmt=" ,IGNORE_DUP_KEY "+rtrim(endingstmt)
where status&1 = 1
update #indexlist
set endingstmt=" ,IGNORE_DUP_ROW "+rtrim(endingstmt)
where status&4 = 4
update #indexlist
set endingstmt=" ,ALLOW_DUP_ROW "+rtrim(endingstmt)
where status&64 = 64

insert #indexlist
select 
	owner,
	name,
        index_name,
        indexid,
	status	 ,
	status2	 ,
        createstmt = 'DROP INDEX ' + rtrim(name) + '.' + rtrim(index_name),
	keylist    ,
	endingstmt ,
	segment=-1
from #indexlist
where  status2 & 2 = 0

insert #indexlist
select 
	owner,
        name,
        index_name,
        indexid,
	status	 ,
	status2	 ,
	createstmt = 'ALTER TABLE ' + rtrim(owner) + '.' + rtrim(name) + ' DROP CONSTRAINT ' + rtrim(index_name) ,
	keylist    ,
	endingstmt ,
	segment=-1
from #indexlist
where  status2 & 2 = 2

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
	/* User wants us to automatically pick a column to build an index on */
	if @dont_format = 1
	begin
		select @ind_column=name from syscolumns where id = object_id(@object) and colid = 1
	end
	select "DROP INDEX  " + rtrim(@object) + ".__ORAC_TEST__"
	select "CREATE CLUSTERED INDEX __ORAC_TEST__ ON " + rtrim(@object) + " (" + rtrim(@ind_column) +") WITH ALLOW_DUP_ROW, FILLFACTOR=80"
	return
end

return(0)
end
