/* Procedure copyright(c) 1993-1995 by Simon Walker */

:r database
go
:r dumpdb
go

if exists (select * 
	   from   sysobjects 
	   where  type = 'P'
	   and    name = "sp__trigger")
begin
    drop procedure sp__trigger
end
go

create procedure sp__trigger (@table_name char(30) = NULL,
	@dont_format char(1) = null
	)
as
begin
    declare @deflt char(30)

    select @deflt = "...................."

    select "table name" = substring(name,1,20),
	   "insert trigger" = substring(isnull(object_name(instrig),@deflt),1,18),
	   "update trigger" = substring(isnull(object_name(updtrig),@deflt),1,18),
	   "delete trigger" = substring(isnull(object_name(deltrig),@deflt),1,18)
    from   sysobjects
    where  type = "U"
    and	   name = isnull(@table_name, name)
    order by name

    return (0)
end
go

grant execute on sp__trigger to public
go
