/*********************************************************************
* Stored procedure  sp__grep  for Sybase SQL Server System 10 
* Author:       Andrew Zanevsky, AZ Databases, Inc.
* Date:         March 16, 1995
* Description:  Searches syscomments table in the current database
*               for occurences of a combination of strings. 
*               Correclty handles cases when a substring begins in 
*               one row of syscomments and continues in the next. 
* Parameters: - @parameter describes the search:
*               string1 {operation1 string2} {operation2 string 3} ...
*               where - stringN is a string of characters enclosed in
*                       curly brackets not longer than 80 characters. 
*                       Brackets may be omitted if stringN does not 
*                       contain spaces or characters: +,-,&;
*                     - operationN is one of the characters: +,-,&.
*               Parameter is interpreted as follows:
*               1.Combine the list of all objects where string1 occurs.
*               2.If there is no more operations in the parameter,
*                 then display the list and stop. Otherwise continue.
*               3.If the next operation is + then add to the list all 
*                   objects where the next string occurs;
*                 else if the next operation is - then delete from the 
*                   list all objects where the next string occurs;
*                 else if the next operation is & then delete from the 
*                   list all objects where the next string does not 
*                   occur (leave in the list only those objects where 
*                   the next string occurs);
*               4.Goto step 2.
*               Parameter may be up to 255 characters long.
*               Parameter may not contain <Line Feed> characters.
*               Please note that operations are applied in the order
*               they are used in the parameter string (left to right). 
*               There is no other priority of executing them. Every 
*               operation is applied to the list combined as a result 
*               of all previous operations.
*               Number of spaces between words of a string matters in a
*               search (e.g. "select *" is not equal to "select  *").
*               Short or frequently used strings (such as "select") may 
*               produce a long result set.
*
*             - @case: i = insensitive / s = sensitive (default).
*
* Examples:     sp__grep employee 
*                 list all objects where string 'employee' occurs;
*               sp__grep employee, i
*                 list all objects where string 'employee' occurs in 
*                 any case (upper, lower, or mixed), such as 
*                 'EMPLOYEE', 'Employee', 'employee', etc.;
*               sp__grep 'employee&salary+department-trigger'
*                 list all objects where either both strings 'employee'
*                 and 'salary' occur or string 'department' occurs, and 
*                 string 'trigger' does not occur;
*               sp__grep '{select FirstName + LastName}'
*                 list all objects where string 
*                 "select FirstName + LastName" occurs;
*               sp__grep '{create table}-{drop table}'
*                 list all objects where tables are created and not 
*                 dropped.
*                 
**********************************************************************/
:r database
go
:r dumpdb
go

if exists (select * 
         from   sysobjects 
         where  type = 'P'
         and    name = "sp__grep")
begin
    drop procedure sp__grep
end
go
/* sp__grep  v1.0  03/16/1995
** Author: Andrew Zanevsky, AZ Databases, Inc. 
** Internet: 71232.3446@compuserve.com */
create proc sp__grep @parameter varchar(255) = null, @case char(1) = 's',
	@dont_format char(1) = null

as

declare @str_no          tinyint, 
        @msg_str_no      varchar(3),
        @operation       char(1), 
        @string          varchar(80), 
        @oper_pos        smallint,
        @context         varchar(255),
        @i               tinyint,
        @longest         tinyint

if @parameter is null /* provide instructions */
begin
    print 'Execute sp__grep "{string1}operation1{string2}operation2{string3}...", [case]'
    print '- stringN is a string of characters up to 80 characters long, '
    print '  enclosed in curly brackets. Brackets may be omitted if stringN '
    print '  does not contain leading and trailing spaces or characters: +,-,&.'
    print '- operationN is one of the characters: +,-,&. Interpreted as or,minus,and.'
    print '  Operations are executed from left to right with no priorities.'
    print '- case: specify "i" for case insensitive comparison.'
    print 'E.g. sp__grep "alpha+{beta gamma}-{delta}&{+++}"'
    return
end

/* Check for <Line Feed> characters */
if charindex( char(10), @parameter ) > 0
begin
    print 'Parameter string may not contain <Line Feed> characters.'
    return
end

if lower( @case ) = 'i'
        select  @parameter = lower( ltrim( rtrim( @parameter ) ) )
else
        select  @parameter = ltrim( rtrim( @parameter ) )

create table #search ( str_no tinyint, operation char(1), string varchar(80), last_obj int )
create table #found_objects ( id int, str_no tinyint )
create table #result ( id int )

/* Parse the parameter string */
select @str_no = 0
while datalength( @parameter ) > 0
begin
  /* Get operation */
  select @str_no = @str_no + 1, @msg_str_no = rtrim( convert( char(3), @str_no + 1 ) )
  if @str_no = 1
    select  @operation = '+'
  else 
  begin
    if substring( @parameter, 1, 1 ) in ( '+', '-', '&' )
        select  @operation = substring( @parameter, 1, 1 ),
                @parameter = ltrim( right( @parameter, datalength( @parameter ) - 1 ) )
    else
    begin
        select @context = rtrim( substring( 
                        @parameter + space( 255 - datalength( @parameter) ), 1, 20 ) )
        print 'Incorrect or missing operation sign before "%1!".', @context
        print 'Search string %1!.', @msg_str_no
        return
    end
  end
  
  /* Get string */
  if datalength( @parameter ) = 0
  begin
      print 'Missing search string at the end of the parameter.'
      print 'Search string %1!.', @msg_str_no
      return
  end
  if substring( @parameter, 1, 1 ) = '{'
  begin
      if charindex( '}', @parameter ) = 0
      begin
          select @context = rtrim( substring( 
                      @parameter + space( 255 - datalength( @parameter) ), 1, 200 ) )
          print 'Bracket not closed after "%1!".', @context
          print 'Search string %1!.', @msg_str_no
          return
      end
      if charindex( '}', @parameter ) > 82
      begin
          select @context = rtrim( substring( 
                      @parameter + space( 255 - datalength( @parameter) ), 2, 20 ) )
          print 'Search string %1! is longer than 80 characters.', @msg_str_no
          print 'String begins with "%1!".', @context
          return
      end        
      select  @string    = substring( @parameter, 2, charindex( '}', @parameter ) - 2 ),
              @parameter = ltrim( right( @parameter, 
                              datalength( @parameter ) - charindex( '}', @parameter ) ) )
  end
  else
  begin
      /* Find the first operation sign */
      select @oper_pos = datalength( @parameter ) + 1
      if charindex( '+', @parameter ) between 1 and @oper_pos
          select @oper_pos = charindex( '+', @parameter )
      if charindex( '-', @parameter ) between 1 and @oper_pos
          select @oper_pos = charindex( '-', @parameter )
      if charindex( '&', @parameter ) between 1 and @oper_pos
          select @oper_pos = charindex( '&', @parameter )

      if @oper_pos = 1
      begin
          select @context = rtrim( substring( 
                      @parameter + space( 255 - datalength( @parameter) ), 1, 20 ) )
          print 'Search string %1! is missing, before "%2!".', @msg_str_no, @context
          return
      end        
      if @oper_pos > 81
      begin
          select @context = rtrim( substring( 
                      @parameter + space( 255 - datalength( @parameter) ), 1, 20 ) )
          print 'Search string %1! is longer than 80 characters.', @msg_str_no
          print 'String begins with "%1!".', @context
          return
      end        

      select  @string    = substring( @parameter, 1, @oper_pos - 1 ),
              @parameter = ltrim( right( @parameter, 
                              datalength( @parameter ) - @oper_pos + 1 ) )
  end
  insert #search values ( @str_no, @operation, @string, 0 )

end
select @longest = max( datalength( string ) ) - 1
from   #search
/* ------------------------------------------------------------------ */
/* Search for strings */
if @case = 'i'
begin
    insert #found_objects
    select a.id, c.str_no
    from   syscomments a, #search c
    where  charindex( c.string, lower( a.text ) ) > 0

    insert #found_objects
    select a.id, c.str_no
    from   syscomments a, syscomments b, #search c
    where  a.id        = b.id
    and    a.number    = b.number
    and    a.colid + 1 = b.colid
    and    charindex( c.string, 
                lower( right( a.text, @longest ) + 
                       space( 255 - datalength( a.text ) ) +
                       substring( b.text, 1, @longest ) ) ) > 0
end
else
begin
    insert #found_objects
    select a.id, c.str_no
    from   syscomments a, #search c
    where  charindex( c.string, a.text ) > 0

    insert #found_objects
    select a.id, c.str_no
    from   syscomments a, syscomments b, #search c
    where  a.id        = b.id
    and    a.number    = b.number
    and    a.colid + 1 = b.colid
    and    charindex( c.string, 
                right( a.text, @longest ) + 
                space( 255 - datalength( a.text ) ) +
                substring( b.text, 1, @longest ) ) > 0
end
/* ------------------------------------------------------------------ */
select distinct str_no, id into #dist_objects from #found_objects
create unique clustered index obj on #dist_objects  ( str_no, id )

/* Apply one operation at a time */
select @i = 0
while @i < @str_no
begin
    select @i = @i + 1
    select @operation = operation from #search where str_no = @i
    
    if @operation = '+'
        insert #result
        select id
        from   #dist_objects 
        where  str_no = @i
    else if @operation = '-'
        delete #result
        from   #result a, #dist_objects b
        where  b.str_no = @i
        and    a.id = b.id
    else if @operation = '&'
        delete #result
        where  not exists 
                ( select 1
                  from   #dist_objects b
                  where  b.str_no = @i
                  and    b.id = #result.id )
end

/* Select results */
select distinct id into #dist_result from #result

/* The following select has been borrowed from the sp_help 
** stored procedure, with addition of #dist_result table. */
select  Name        = o.name,
        Owner       = convert(char(15), user_name(uid)),
        Object_type = convert(char(22), m.description + x.name)
from    #dist_result           d,
        sysobjects             o, 
        master.dbo.spt_values  v,
        master.dbo.spt_values  x, 
        master.dbo.sysmessages m
where   d.id = o.id
and     o.sysstat & 2063 = v.number
and     v.type = "O"
and     v.msgnum = m.error
and     isnull(m.langid, 0) = @@langid
and     m.error between 17100 and 17109
and     x.type = "R"
and     o.userstat & -32768 = x.number
order by Object_type desc, Name asc

go
grant execute on sp__grep to public
go
