        select 
        Username  = u.name
        from    sysusers u, sysusers g, master.dbo.syslogins m
        where   u.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
UNION
        select
        User_name  = convert(char(17), u.name)
        from    sysusers u, sysusers g, master.dbo.syslogins m,sysalternates a
        where   a.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and     a.altsuid=u.suid
order by 1
