/************************************************************************\ 
|* Procedure Name:	sp__depends
|*									
\************************************************************************/ 

:r database
go
:r dumpdb
go

if object_id('sp__depends') is not null
    drop proc sp__depends
go
create procedure sp__depends (
	@objname	varchar(30) = null,
	@format 	varchar(30) = null,
		@dont_format char(1) = null
	) as
begin
    /*
    ** AUTHOR:	Q Vincent Yin (umyin@mctrf.mb.ca),     Sep 1995
    ** PURPOSE: It's a superset of sp_depends.
    ** REMARKS:
    **    This proc can handle usertypes, defaults and rules that are not 
    **	  covered by the original proc sp_depends.  For tables, procs, etc, that
    **    are covered by sp_depends, this proc will simply call sp_depends.
    **	  It prints usage and quits if invoked without arguments. Otherwise:
    **    For each line printed by this proc:
    **       If @format=null, output is in tabular format similar to sp_depends.
    **       If @format='drop', output is in isql format.
    **	  For example,
    **		exec sp__depends 'my_rule', 'drop'
    **	  will print (not execute) isql scripts that would unbind my_rule from 
    **    all attached columns and usertypes, and then drop my_rule.  By running
    **    the generated isql script, you won't encounter this frustrating error:
    **		Msg 3716, Level 16, State 1:
    **		The rule 'my_rule' cannot be dropped because it is bound to
    **		one or more column.
    **
    ** BUGS:
    **    - @format='drop' doesn't guarentee the successful dropping of usertype
    **      because the usertype may have been used by some tables and procs.
    **	  - I didn't pay much attention to the owners of objects since all
    **      objects at our site are owned by dbo.
    */

    declare @id int,		/* object_id or usertype id of @objname */
	    @type varchar(30),  /* sysobjects.type */
	    @go   char(3)	/* char(10) + 'go' */

    if @objname is null
	 begin
			select "object"=object_name(id),"dependant"=object_name(depid)
			from 	 sysdepends
		return
	 end
   
    select @format = lower(@format), @go = char(10) + 'go'
    if @objname is null or isnull(@format,'drop') not in ('drop')
    begin
	print "Usage: sp__depends @objname='object_name'  [, @format='drop']"
	return 1
    end

    if @objname like '%.%'
    begin
	print "Object name must not contain db or owner prefix."
	return 1
    end

    /* Is it a user type?  See also: sp_droptype. */
    select @id = 0	/* Initialize so we can tell if we can't find it. */
    select @id = usertype
	from systypes
	where user_id() in (uid,1) and name = @objname and usertype > 99
    if @id != 0	/* found */
    begin
	print "/* %1! is a usertype. */", @objname
	if not exists (select * from syscolumns where usertype = @id)
	begin
	    print "/* Datatype isn't used by any object. */"
	end
	else if @format is null
	begin
	    select object = o.name, type = o.type,
		owner = convert(char(10), user_name(o.uid)), column = c.name
	    from syscolumns c, sysobjects o
	    where c.usertype = @id and
		  c.id = o.id
	    order by object, column
	end
	
	if @format = 'drop'
	begin
	    print "exec sp_droptype '%1!' %2!", @objname, @go
	end
	return
    end

    /* Now, not a usertype. */
    select @id = id, @type = type from sysobjects where name = @objname
    if @id = 0
    begin
	print "Object does not exist in this database."
	return 1
    end

    if @type in ('U', 'S', 'V', 'P', 'TR')
    begin
	if @format is null
	begin
	    exec sp_depends @objname
	end
	else if @format = 'drop'
	begin
	    if @type = 'U'
		print "drop table '%1!' %2!", @objname, @go
	    if @type = 'V'
		print "drop view '%1!' %2!", @objname, @go
	    else if @type = 'P'
		print "drop proc '%1!' %2!", @objname, @go
	    else if @type = 'TR'
		print "drop trigger '%1!' %2!", @objname, @go
	end
    end
    else if @type = 'D'
    begin
	print "/* %1! is a default. */", @objname
	if exists (select * from syscolumns c where @id = c.cdefault)
	begin
	    print "/* ...bound to the following columns: */"
	    if @format is null
	    begin
		select object = object_name(c.id),
		   owner  = convert(char(10), user_name(o.uid)),
		   column = c.name
		from sysobjects o, syscolumns c
		where c.cdefault = @id and
		      c.id = o.id
		order by object, column
	    end
	    else if @format = 'drop'
	    begin
		select "exec sp_unbindefault '" +
			rtrim(object_name(c.id))+'.'+
			rtrim(c.name) + "'" + @go
		    from syscolumns c
		    where c.cdefault = @id
		    order by object_name(c.id), c.name
	    end
	end
	if exists (select * from systypes t where @id = t.tdefault)
	begin
	    if @format is null
	    begin
		print ""
		print "/* ...bound to the following usertypes: */"
		select usertype = t.name, owner = user_name(t.uid)
		    from systypes t
		    where t.tdefault = @id
	    end
	    else if @format = 'drop'
	    begin
		select "exec sp_unbindefault '" + name + "'" + @go
		    from systypes t
		    where t.tdefault = @id
	    end
	end
        if @format = 'drop'
	begin
	    print "drop default %1!", @objname
	    print "go"
	end
    end
    else if @type = 'R'
    begin
	print "/* %1! is a rule. */", @objname
	if exists (select * from syscolumns c where @id = c.domain)
	begin
	    if @format is null
	    begin
		print "/* ...bound to the following columns: */"
		select object = object_name(c.id),
			owner = convert(char(10), user_name(o.uid)),
		       column = c.name
		    from sysobjects o, syscolumns c
		    where c.domain = @id and 
			  o.id = c.id
		    order by object, column
	    end
	    else if @format = 'drop'
	    begin
		select "exec sp_unbindrule '" + object_name(c.id) + "." +
			c.name + "'" + @go
		    from syscolumns c
		    where c.domain = @id
		    order by object_name(c.id), c.name
	    end
	end
	if exists (select * from systypes t where @id = t.domain)
	begin
	    if @format is null
	    begin
		print ""
		print "/* ...bound to the following usertypes: */"
		select usertype = t.name, owner = user_name(t.uid)
		    from systypes t
		    where t.domain = @id
	    end
	    else if @format = 'drop'
	    begin
		select "exec sp_unbindrule '" + name + "'" + @go
		    from systypes t
		    where t.domain = @id
	    end
	end
        if @format = 'drop'
	begin
	    print "drop rule %1!", @objname
	    print "go"
	end
    end
    else
    begin
	print "Can't handle object type %1!.", @type
	return 1
    end

end
go
grant execute on sp__depends to public
go

