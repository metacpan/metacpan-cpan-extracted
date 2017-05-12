/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revuser")
begin
    drop proc sp__revuser
end
go

create procedure sp__revuser(@username varchar(30) = null)
as
begin

if @username is NULL
begin
	/* Get Regular Users */
	select  "exec sp_adduser '"+m.name+"','"+u.name+"','"+g.name+"'"
	from	sysusers u, sysusers g, master.dbo.syslogins m
	where   u.suid = m.suid
	and     u.gid  = g.uid
	and     u.uid  != u.gid
	and	  u.suid!=1
	and     u.uid not in ( select uid from model..sysusers )

    return (0)
end
else 
begin
        /* Get Regular Users */
        select  "exec sp_adduser '"+m.name+"','"+u.name+"','"+g.name+"'"
        from    sysusers u, sysusers g, master.dbo.syslogins m
        where   u.suid = m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and       u.suid!=1
        and     u.uid not in ( select uid from model..sysusers )
	and u.uid = USER_ID(@username)

    return (0)
end
end
go

grant execute on sp__revuser to public
go
