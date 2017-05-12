/* Procedure copyright(c) 1993-1995 by Simon Walker */

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = 'P'
           and    name = "sp__noindex")
begin
    drop procedure sp__noindex
end
go

create procedure sp__noindex ( @dont_format char(1) = null) 
as
begin

    set nocount on

    select No_Indexes = o.name,
	   "Rows" = rowcnt(i.doampg),
		Pages= data_pgs(o.id,i.doampg)
    from   sysobjects o, sysindexes i
    where  o.type = "U"
    and    o.id = i.id
    and    i.indid = 0
    and	   o.id not in (select o.id
		        from   sysindexes i,
		 	       sysobjects o
		        where  o.id = i.id
		        and    o.type = "U"
		        and    i.indid > 0)
 
    select No_Clustered_Index = o.name,
	   "Rows" = rowcnt(i.doampg),
		Pages= data_pgs(o.id,i.doampg)
    from   sysindexes i,
	   sysobjects o
    where  o.id = i.id
    and	   o.type= "U"
    and	   i.indid = 0
    and	   o.id in (select o.id
		        from   sysindexes i,
		 	       sysobjects o
		        where  o.id = i.id
		        and    o.type = "U"
		        and    i.indid > 0)

end
go

grant execute on sp__noindex to public
go
