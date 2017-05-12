/* Procedure copyright(c) 1996 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__id
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__id"
           and    type = "P")
   drop proc sp__id

go

/*---------------------------------------------------------------------------*/

create proc sp__id ( @dont_format char(1) = null )
AS 
BEGIN

set nocount on

select  "db"=convert(char(20),db_name()), 
	"login"=convert(char(20),suser_name()), 
	"id"=convert(char(4),suser_id()), 
	"db name"=convert(char(20),user_name())
return(0)

END

go

grant execute on sp__id  TO public
go


