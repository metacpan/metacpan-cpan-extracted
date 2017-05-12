/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__ls.sp
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__ls"
           and    type = "P")
   drop proc sp__ls
go
create proc sp__ls( @objname varchar(30) = '%',
	@dont_format char(1) = null
	)
AS 
BEGIN

if @objname in ('D','P','TR','U','V','S','R')
		  select Object_name  = name,
					Type 			 = type,
					Owner 		 = convert(char(15),user_name(uid)),
					Created_date = convert(char(20),crdate)
		  from   sysobjects 
		  where  type = @objname 
		  order  by name

/* do a simple ls */
else if exists (select * from sysobjects where name like '%'+@objname+'%')
		  select Object_name  = name,
					Type 			 = type,
					Owner 		 = convert(char(15),user_name(uid)),
					Created_date = convert(char(20),crdate)
		  from   sysobjects 
		  where  name like '%' + @objname + '%'
		  order  by name
else	 print "No Object Found"


return(0)

END
go
grant execute on sp__ls  TO public
go

