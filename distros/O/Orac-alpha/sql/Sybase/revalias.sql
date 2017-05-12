/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revalias")
begin
    drop proc sp__revalias
end
go

create procedure sp__revalias ( @dont_format char(1) = null)
as
begin
	 /* Add Any Alias */
	 select  "exec sp_addalias '"+m.name+"','"+u.name+"'"
	 from	   sysusers u, sysusers g, master.dbo.syslogins m,sysalternates a
	 where   a.suid = m.suid
	 and     u.gid  = g.uid
	 and     u.uid  != u.gid
	 and		a.altsuid=u.suid

    return (0)
end
go

grant execute on sp__revalias to public
go
