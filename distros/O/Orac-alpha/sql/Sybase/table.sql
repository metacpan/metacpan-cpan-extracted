:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp_table")
begin
    drop proc sp_table
end
go

create procedure sp_table (@tableName varchar(50)= null)
as
begin

DECLARE @objid int

IF @tableName IS NULL
BEGIN
  SELECT convert(varchar(70), "Usage: sp_table @tableName")
    return -1
END

SELECT  @objid=object_id(@tableName) from sysobjects where type in ('S', 'U')
IF @objid IS NULL
BEGIN
  SELECT convert(varchar(70), "Table "+@tableName+" Not Found")
    return -1
END

print ""
set nocount on
exec sp__revtable @tableName

print ""
set nocount on
exec sp__helprotect @tableName

return (0)
end
go
grant exec on sp_table to public
go
