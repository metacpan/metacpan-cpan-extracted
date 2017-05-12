/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__helpobject.sp
**
******************************************************************************/
:r database
go
:r dumpdb
go

IF EXISTS (SELECT * FROM sysobjects
           WHERE  name = "sp__helpobject"
           AND    type = "P")
   DROP PROC sp__helpobject

go
create proc sp__helpobject( 
                @objectname        varchar(92) = NULL,
						 @dont_format char(1) = null
						 )
AS 
BEGIN

set nocount on

exec sp__helptable @objectname
print ""
exec sp__helpview @objectname
print ""
exec sp__helpproc @objectname
print ""
exec sp__helprule @objectname
print ""
exec sp__helpdefault @objectname
print ""
exec sp__helprule @objectname
print ""
exec sp__helptrigger @objectname

set nocount off
END

go

GRANT EXECUTE ON sp__helpobject  TO public
go
