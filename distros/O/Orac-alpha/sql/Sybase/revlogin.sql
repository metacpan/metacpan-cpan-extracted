/* Procedure copyright(c) 1995 by Edward M Barlow */
:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__revlogin")
begin
    drop proc sp__revlogin
end
go

create procedure sp__revlogin( @dont_format char(1) = null)
as
begin
   create table #tmp
	(
		txt varchar(255)
	)

	if exists ( select * from master..sysdatabases where name='sybsystemprocs')
	begin
		if exists ( select * from master..syslogins where language is null )
		insert #tmp
		select 
			"exec sp_addlogin '"+name+"','N.A.','"+dbname+"'"
		from	master.dbo.syslogins m
		where language is null
		and name not in ('sa','probe')

		if exists ( select * from master..syslogins where language is not null )
		insert #tmp
		select 
			"exec sp_addlogin '"+name+"','N.A.','"+dbname+"','"+language+"'"
		from	master.dbo.syslogins m
		where language is not null
		and name not in ('sa','probe')
	end
	else
	begin
		if exists ( select * from master..syslogins where language is null )
		insert #tmp
		select 
			"exec sp_addlogin '"+name+"','"+convert(varchar(30),password)+"','"+dbname+"'"
		from	master.dbo.syslogins m
		where language is null
		and name not in ('sa','probe')

		if exists ( select * from master..syslogins where language is not null )
		insert #tmp
		select 
			"exec sp_addlogin '"+name+"','"+convert(varchar(30),password)+"','"+dbname+"','"+language+"'"
		from	master.dbo.syslogins m
		where language is not null
		and name not in ('sa','probe')
	end

	select txt from #tmp
	drop table #tmp

   return (0)
end
go

grant execute on sp__revlogin to public
go
