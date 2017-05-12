/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	proclib_version					
|*	Returns the Version Of Extended Stored Procedure Library
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__proclib_version")
begin
    drop proc sp__proclib_version
end
go

/* If @dbname=NoPrint no print statements will be run */
create procedure sp__proclib_version ( @dont_format char(1) = null)
as

select 4.40

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__proclib_version to public
go
