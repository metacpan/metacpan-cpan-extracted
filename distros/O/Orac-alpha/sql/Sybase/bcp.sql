/* Procedure copyright(c) 1993-1995 by Simon Walker */

/************************************************************************\
|* Procedure Name:      sp__bcp                                         *|
|*                                                                      *|
|* Description:         Produces bcp script to copy out tables in       *|
|*                      database.                                       *|
|*            Produces the following commands for each table:           *|
BCP [db]..[table] out [table].dat -U[login] -P[password] -S[server] -c [commands]
|*                                                                      *|
|*                  If no parameters are supplied, the values for       *|
|*                  login, server, file ext, and database are found     *|
|*                  from the available information in the current       *|
|*                  connection.                                         *|
|*                                                                      *|
|* Usage:               sp__bcp server      (defaults to current)       *|
|*                                 database      (defaults to current)  *|
|*                                 user            (defaults to current)*|
|*                                 password      (defaults to current)  *|
|*                                 direction      (defaults to out)     *|
|*                                 extension      (defaults to .dat)    *|
|*                                 commands      (defaults to null)     *|
|*                                                                      *|
|*                                                                      *|
\************************************************************************/

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__bcp")
begin
    drop proc sp__bcp
end
go

create procedure sp__bcp (@server        char(30) = NULL,
                          @database      char(30) = NULL,
                          @user          char(30) = NULL,
                          @password      char(30) = NULL,
                          @direction     char(3)  = NULL,
                          @extension     char(30) = NULL,
                          @commands      char(30) = NULL,
									  @dont_format char(1) = null
									  )
as
begin

    declare @name  char(30),
            @file  char(30),
            @text  varchar(120)

    if @server is null
	 begin
    	print ''
    	print '# Usage is...'
		print ''
		print '# sp__bcp {server}, [database], [user], [password], '
		print '#          [direction], [extension], [commands]'
		print '# where...'
		print '# {server}    Server name (should really be entered since'
		print '#                        @@servername is rarely defined)'
		print '# [database]  Defaults to database procedure is run in'
		print '# [user]      Defaults to current username'
		print '# [password]  Defaults to current password'
		print '# [direction] Defaults to out'
		print '# [extension] Defaults to .dat'
		print '# [commands]  Allows you to enter further switching'
		print ''
		print ''
	 end

    /* Get the server name */
    if @server is NULL
      select @server = @@servername

    if @server is NULL
    begin
      print ''
      print 'Server is undefined'
      print ''
      return(0)
    end

    /* Get the database name */
    if @database is null
      select @database = db_name()

    /* Get the user name */
    if @user is NULL
      select @user = suser_name()

    /* Get the password */
    if @password is NULL
      select @password = password
      from   master..syslogins
      where  name = suser_name()

    /* Get the file transfer direction */
    if @direction is NULL
      select @direction = "out"
    else
      select @direction = lower(@direction)

    /* Get the file extension */
    if @extension is NULL
      select @extension = "dat"
    else
      select @extension = lower(@extension)

    /* Create a temporary table of tablenames */
    create table #tab (name      char(30),
                   file      char(30),
                   text      varchar(120) null)

    /* Insert the table names into the temporary table */
    insert #tab
    select name,
         file = name,
         text = null
    from   sysobjects
    where  type = "U"

    /* extract the commands in two separate batches... */
    update #tab
    set    text = "bcp " +
         rtrim(@database) +
         ".." + 
         rtrim(name) +
         " " + 
         rtrim(@direction) +
         " " + 
         rtrim(file) +
         "." +
         rtrim(@extension) +
         " -U" +
         rtrim(@user) +
         " -P" +
         rtrim(@password) +
         " -S" +
         rtrim(@server) +
         " -c " +
         rtrim(@commands)
    from   #tab

    /* Loop through tables in the temporary table */
    while exists (select * from #tab)
    begin
      select @name = min(name)
      from   #tab

	   if  @direction='out' 
			and ( select db_name() ) = @database
			and ( select rowcnt(i.doampg)
					from sysindexes i
					where id=object_id(@name)
					and indid<=1 ) = 0
		begin
      	select @text = "echo # zero rows - not BCPing "+rtrim(@name)
      	print @text
		end
		else
		begin
      	print 'echo ""'
      	print 'echo ""'

      	/* Let the world know what is going on */
      	select @text = "echo BCP "+rtrim(@direction)+
                   " table "+rtrim(@database)+
                   ".."+rtrim(@name)
      	print @text

      	/* Extract the bcp commands */
      	select @text = rtrim(text)
      	from   #tab
      	where  name = @name

      	/* Print out the command */
      	print @text
      	print ""
		end

      delete #tab
      where  name = @name
    end

    /* Remove the temporary table */
    drop table #tab

    return (0)
end
go

grant execute on sp__bcp to public
go
