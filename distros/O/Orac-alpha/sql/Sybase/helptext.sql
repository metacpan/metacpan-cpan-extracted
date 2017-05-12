/*********************************************************************
* Stored procedure  sp__helptext  for Sybase or Microsoft SQL Server 
* Author:       Andrew Zanevsky, AZ Databases, Inc.
* Date:         March 16, 1995
* Description:  Works similar to standard system stored procedure
*               sp_helptext. Correclty handles cases when a substring 
*               begins in one row of syscomments table and continues 
*               in the next (no split lines!).
*               Uses print command (not select) to generate the result
*               for technical reasons.
* Parameters: - @objname - object name
**********************************************************************/
:r database
go
:r dumpdb
go

if exists (select * 
         from   sysobjects 
         where  type = 'P'
         and    name = "sp__helptext")
begin
    drop procedure sp__helptext
end
go

create procedure sp__helptext ( @objname varchar(92), @dont_format char(1) = null)
as
declare @text_count int,
        @text       varchar(255),
        @line       varchar(255),
        @split      tinyint,
        @lf         char(1)
select  @lf = char(10)

/*
if @@trancount = 0
begin
        set transaction isolation level 1
        set chained off
end
*/

/***** Make sure the @objname is local to the current database. */
if @objname like "%.%.%" and
        substring(@objname, 1, charindex(".", @objname) - 1) != db_name()
begin
        print "Object must be in the current database."
        return (1)
end

/***** See if @objname exists. */
if (object_id(@objname) is NULL)
begin
        print "Object does not exist in this database."
        return (1)
end

select  text
into    #text
from    syscomments 
where   id = object_id(@objname)

select  @text_count = @@rowcount

/***** Parse and print the text one line at a time. */        
set rowcount 1
while @text_count > 0
begin
        select  @text_count = @text_count - 1,
                @text  = text + space( ( 255 - datalength( text ) ) 
                                       * sign( @text_count ) ),
                @split = charindex( @lf, text )
        from    #text

        delete  #text
        
		  if @split = 0
		  begin
				/* No line feeds on line */
				select @text=@line+@text, @line=""
				print @text
		  end
        while   @split > 0
        begin
                select  @line  = @line + substring( @text, 1, @split - 1 ),
                        @text  = right( @text, datalength( @text ) - @split )
                print "%1!", @line
                select  @split = charindex( @lf, @text ),
                        @line  = NULL
        end

        if @text_count = 0
	begin
		if ascii(@text) = 0
                begin
                        select @text=substring(rtrim(@text),2,255)
                end

                print "%1!", @text
	end
        else
                select  @line = @text        
end
set rowcount 0
print ""

go
grant execute on sp__helptext to public
go

