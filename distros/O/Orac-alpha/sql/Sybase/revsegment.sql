/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revsegment")
begin
    drop proc sp__revsegment
end
go

create procedure sp__revsegment( @dont_format char(1) = null)
as
begin
		/* syntax sp_addsegment segname,devname */
		select "exec sp_addsegment '"+s.name+"','"+d.name+"'"
		from master..sysdevices d, master..sysusages u,syssegments s
		where vstart between low and high
		 and d.status & 2 = 2
		 and u.dbid=db_id()
		 and s.segment >2 
		 and segmap & power(2,s.segment)  != 0

   return (0)
end
go

grant all on sp__revsegment to public
go
