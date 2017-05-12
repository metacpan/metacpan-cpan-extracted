/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__helpproc.sp
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__helpproc"
           and    type = "P")
   drop proc sp__helpproc

go
CREATE PROC sp__helpproc( @objname        varchar(92) = NULL,
	@dont_format char(1) = null
	)
AS 
BEGIN

if exists (select * from sysobjects where name=@objname and type='P' )
		  select Procedure_name = name,
					Owner = convert(char(15),user_name(uid)),
					Created_date = convert(char(2),crdate,6)
									+substring(convert(char(9),crdate,6),4,3)
									+substring(convert(char(9),crdate,6),8,2)
		  from   sysobjects 
		  where  name =@objname
		  and    type = "P"
		  order  by name
else if exists (select * from sysobjects where name like "%"+@objname+"%" and type='P' )
		  select Procedure_name = name,
					Owner = convert(char(15),user_name(uid)),
					Created_date = convert(char(2),crdate,6)
									+substring(convert(char(9),crdate,6),4,3)
									+substring(convert(char(9),crdate,6),8,2)
		  from   sysobjects 
		  where  name like "%"+@objname+"%"
		  and    type = "P"
		  order  by name
else	 print "No Procedures In Database"

END

go

GRANT EXECUTE ON sp__helpproc  TO public
go
