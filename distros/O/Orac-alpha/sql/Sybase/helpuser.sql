/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\
|* Procedure Name:      sp__helpuser                                  	*|
|*                                                                      *|
|* Description:                                                         *|
|*                                                                      *|
|* Usage:               sp__helpuser                             	*|
|*                                                                      *|
|* Modification History:                                                *|
|*                                                                      *|
\************************************************************************/
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__helpuser")
begin
    drop proc sp__helpuser
end
go

create procedure sp__helpuser(@parm char(1)=NULL,
	@dont_format char(1) = null
	)
as
begin
	create table #tmp
	(
	Login_name char(17) null, 
	User_name  char(17) null,
	Group_name char(17) null, 
	Default_db char(17) null,
	Is_Alias   char(1) null
	)

	/* Get Regular Logins */
	insert #tmp
	select 
	Login_name = m.name,
	User_name  = u.name,
	Group_name = g.name,
	Default_db = m.dbname,
	Is_Alias   = NULL
	from	sysusers u, sysusers g, master.dbo.syslogins m
	where   u.suid *= m.suid
	and     u.gid  = g.uid
	and     u.uid  != u.gid

	/* Add Any Aliases */
	insert #tmp
	select
	Login_name = convert(char(17), m.name),
	User_name  = convert(char(17), u.name),
	Group_name = convert(char(17), g.name),
	Default_db = convert(char(17), m.dbname),
	Is_Alias   = convert(char(1),'Y')
	from	sysusers u, sysusers g, master.dbo.syslogins m,sysalternates a
	where   a.suid *= m.suid
	and     u.gid  = g.uid
	and     u.uid  != u.gid
	and	a.altsuid=u.suid

	if @parm is null
	select  
		Login_name, User_name, "Alias"=isnull(Is_Alias,""), Group_name, Default_db
	from #tmp
	order by User_name
	else
	select  
		Login_name, User_name, "Alias"=isnull(Is_Alias,""), Group_name, Default_db,db_name()
	from #tmp
	order by User_name


	drop table #tmp
    return (0)
end
go

grant execute on sp__helpuser to public
go
