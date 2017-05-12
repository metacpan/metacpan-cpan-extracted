/* Procedure copyright(c) 1996 by Ed Barlow */
/* Forgive this one - i need it for other stuff */

:r database
go
:r dumpdb
go

if exists (select * 
	   from   sysobjects 
	   where  type = 'P'
	   and    name = "sp__get_tmp_error")
begin
    drop procedure sp__get_tmp_error
end
go

create table #error ( msg varchar(127) not NULL )
go

create procedure sp__get_tmp_error
as
	select msg from #error
go

grant execute on sp__get_tmp_error to public
go
