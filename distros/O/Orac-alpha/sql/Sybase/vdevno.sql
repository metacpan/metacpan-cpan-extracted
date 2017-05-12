/* Procedure copyright(c) 1993-1995 by Simon Walker */

:r database
go
:r dumpdb
go

if exists (select * 
	   from   sysobjects 
	   where  type = 'P'
	   and    name = "sp__vdevno")
begin
    drop procedure sp__vdevno
end
go

create procedure sp__vdevno( @dont_format char(1)=NULL )
as
begin
    declare @max_devices	int
    declare @vdevno		int


    select @max_devices = value - 1
    from   master..syscurconfigs
    where  config = 116

    create table #vdevno (vdevno	int,
			  device	char(30))

    select @vdevno = 0

    while (@vdevno <= @max_devices)
    begin
	insert	#vdevno
	values	(@vdevno, "      -- free --")

	select	@vdevno = @vdevno + 1
    end

    update #vdevno
    set	   device = d.name
    from   #vdevno vd,
	   master..sysdevices d,
	   master..spt_values v
    where  vdevno = convert(tinyint, substring(convert(binary(4), d.low),
					       v.low, 1))
    and	   v.type = "E"
    and	   v.number = 3
    and	   status & 2 = 2

	 if @dont_format is not null
    	print "****** DEVICE ID'S USED ******"

    select vdevno = "  "+str(vdevno,3)+"  ",
	   device
    from   #vdevno
    order by vdevno

    return (0)
end
go

grant execute on sp__vdevno to public
go
