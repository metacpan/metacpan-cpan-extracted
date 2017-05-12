        select
        User_name  = u.name
        from    sysusers u, sysusers g, master.dbo.syslogins m
        where   u.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and     u.suid not between -16390 and -16383
        and g.name = '%s'
UNION
        select
        User_name  = convert(char(14), u.name)
        from    sysusers u, sysusers g, master.dbo.syslogins m,sysalternates a
        where   a.suid *= m.suid
        and     u.gid  = g.uid
        and     u.uid  != u.gid
        and     a.altsuid=u.suid
        and g.name = '%s'

