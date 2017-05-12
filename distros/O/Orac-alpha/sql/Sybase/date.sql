/* Procedure copyright(c) 1993-1995 by Simon Walker */

:r database
go
:r dumpdb
go

if exists (select * 
	   from   sysobjects 
	   where  type = 'P'
	   and    name = "sp__date")
begin
    drop procedure sp__date
end
go

create procedure sp__date (@date	datetime = NULL,
	@dont_format char(1) = null
	)
as
begin
    declare @style	int
    declare @msg	varchar(80)

    select @style = 0

    if @date is NULL
	select @date = getdate()

    while (@style <= 12)
    begin
	select @msg = 	convert(char(4), @style) + 
			convert(char(30), @date, @style) +
			convert(char(5), @style+100) +
			convert(char(30), @date, @style+100)

	print @msg

	select @style = @style + 1
    end

end
go

grant execute on sp__date to public
go
