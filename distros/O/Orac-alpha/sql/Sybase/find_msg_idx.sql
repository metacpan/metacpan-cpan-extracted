/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__find_missing_index.sp
**
** Summary		: Find indexes that are missing (foreign key exists
**							 but no index )
**
******************************************************************************/

:r database
go
:r dumpdb
go

IF EXISTS (SELECT * FROM sysobjects
           WHERE  name = "sp__find_missing_index"
           AND    type = "P")
   DROP PROC sp__find_missing_index

go

CREATE PROC sp__find_missing_index( @objname char(32) = NULL, @dont_format char(1)=NULL )
AS 

declare @oid int
set nocount on

select  @oid = object_id(@objname)

create table #indexlist (
	id         int not null,
	key1	   char(30) null,
	key2	   char(30) null,
	key3	   char(30) null,
	key4	   char(30) null,
	key5	   char(30) null,
	key6	   char(30) null
)

if @oid is null
begin
		  insert into   #indexlist
		  select distinct
				id = i.id
			  ,key1 = index_col(object_name(id),indid,1)
			  ,key2 = index_col(object_name(id),indid,2)
			  ,key3 = index_col(object_name(id),indid,3)
			  ,key4 = index_col(object_name(id),indid,4)
			  ,key5 = index_col(object_name(id),indid,5)
			  ,key6 = index_col(object_name(id),indid,6)
		  from  sysindexes i
		  where indid > 0

		  if @dont_format is not null and @dont_format != 'S'
				delete #indexlist
				from   #indexlist i, sysobjects o
				where  i.id = o.id
				and    o.type ='S'

end
else
		  insert into   #indexlist
		  select distinct
				id = i.id
			  ,key1 = index_col(object_name(id),indid,1)
			  ,key2 = index_col(object_name(id),indid,2)
			  ,key3 = index_col(object_name(id),indid,3)
			  ,key4 = index_col(object_name(id),indid,4)
			  ,key5 = index_col(object_name(id),indid,5)
			  ,key6 = index_col(object_name(id),indid,6)
		  from  sysindexes i
		  where indid > 0
			and   id = @oid 

if @@rowcount = 0
begin
	print "No Indexes Found in Current Database"
	return
end

create table #keylist (
	id       int null,
	key1	   char(30) null,
	key2	   char(30) null,
	key3	   char(30) null,
	key4	   char(30) null,
	key5	   char(30) null,
	key6	   char(30) null
)

if @oid is null
		  insert #keylist
		  select distinct id,col_name(id,key1),col_name(id,key2),col_name(id,key3),
					  col_name(id,key4),col_name(id,key5),col_name(id,key6)
		  from   syskeys
		  UNION
		  select distinct depid,col_name(depid,depkey1),col_name(depid,depkey2),
				  col_name(depid,depkey3), col_name(depid,depkey4),
				  col_name(depid,depkey5),col_name(depid,depkey6)
		  from   syskeys
else
		  insert #keylist
		  select distinct id,col_name(id,key1),col_name(id,key2),col_name(id,key3),
					  col_name(id,key4),col_name(id,key5),col_name(id,key6)
		  from   syskeys
		  where  id = @oid 
		  UNION
		  select distinct depid,col_name(depid,depkey1),col_name(depid,depkey2),
				  col_name(depid,depkey3), col_name(depid,depkey4),
				  col_name(depid,depkey5),col_name(depid,depkey6)
		  from   syskeys
		  where depid = @oid 

delete #keylist where id is null

/*
select key1, key2 from #indexlist
select object_name(id),substring(key1,1,10),substring(key2,1,10) from #keylist
*/

/* Kill system tables - nothing you can do about them */
delete #keylist
from   #keylist k,sysobjects o
where  o.id = k.id
and    o.type='S'

/* It is OK to have longer or shorter indexes, just not different */
delete #keylist
from   #keylist k,#indexlist i
where  k.id = i.id
and    k.key1 = i.key1
and    isnull( k.key2, isnull(i.key2,"" )) = isnull( i.key2,"" )
and    isnull( k.key3, isnull(i.key3,"" )) = isnull( i.key3,"" )
and    isnull( k.key4, isnull(i.key4,"" )) = isnull( i.key4,"" )
and    isnull( k.key5, isnull(i.key5,"" )) = isnull( i.key5,"" )
and    isnull( k.key6, isnull(i.key6,"" )) = isnull( i.key6,"" )

delete #keylist
from   #keylist k,#indexlist i
where  k.id = i.id
and    k.key1 = i.key1
and    isnull( i.key2, isnull(k.key2,"" )) = isnull( k.key2,"" )
and    isnull( i.key3, isnull(k.key3,"" )) = isnull( k.key3,"" )
and    isnull( i.key4, isnull(k.key4,"" )) = isnull( k.key4,"" )
and    isnull( i.key5, isnull(k.key5,"" )) = isnull( k.key5,"" )
and    isnull( i.key6, isnull(k.key6,"" )) = isnull( k.key6,"" )

/* NOW SHOW ME STUFF THAT HAS BAD KEYS */
if @dont_format is null
	select objname=substring(object_name(id),1,22),
			key1=substring(isnull(key1,""),1,13),
			key2=substring(isnull(key2,""),1,13),
       	key3=substring(isnull(key3,""),1,13),
			key4=substring(isnull(key4,""),1,13) 
	from #keylist
	order by object_name(id)
else
	select object_name(id),key1,key2,key3,key4,key5,key6
	from #keylist

go

GRANT EXECUTE ON sp__find_missing_index  TO public
go
