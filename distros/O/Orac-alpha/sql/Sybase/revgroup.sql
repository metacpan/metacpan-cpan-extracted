/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revgroup")
begin
    drop proc sp__revgroup
end
go

create procedure sp__revgroup( @dont_format char(1) = null)
as
begin
	/* Get Regular Users */
	select  "exec sp_addgroup '"+name+"'"
	from	sysusers u
	where   u.uid  = u.gid
	and	 uid!=0
	and   uid not in ( select uid from model..sysusers )

    return (0)
end
go

grant execute on sp__revgroup to public
go
