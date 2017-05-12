/* Procedure copyright(c) 1993-1995 by Simon Walker */

:r database
go
:r dumpdb
go

if exists (select * 
         from   sysobjects 
         where  type = 'P'
         and    name = "sp__who")
begin
    drop procedure sp__who
end
go

create procedure sp__who(@parm varchar(30) = null, @dont_format char(1) = null)
as
begin
    declare @parmsuid int , @parmdbid int
 
 
    if @parm is not NULL 
    begin
        select @parmsuid = suser_id(@parm)
        if @parmsuid is NULL
        begin
            select @parmdbid = db_id(@parm)
            if @parmdbid is null
            begin
               print "No login exists with the supplied name."
               return (1)
            end
        end

        select spid = convert(char(4), spid),
           loginame= substring(suser_name(suid), 1, 10),
			  hostinfo=substring(rtrim(hostname)+" "+rtrim(program_name)+" "+rtrim(hostprocess),1,22),
           dbname=substring(db_name(dbid), 1, 10),
           status=convert(char(8), status),
           cmd,
           bk = convert(char(2), blocked)
        from   master..sysprocesses
        where  isnull(@parmdbid,dbid) = dbid
        and    isnull(@parmsuid,suid) = suid

    end
    else

    select spid = convert(char(4), spid),
           loginame= substring(suser_name(suid), 1, 10),
			  hostinfo=substring(rtrim(hostname)+" "+rtrim(program_name)+" "+rtrim(hostprocess),1,22),
           dbname = substring(db_name(dbid), 1, 10),
           status = convert(char(8), status),
           cmd,
           bk = convert(char(2), blocked)
    from   master..sysprocesses

    return
end
go

grant execute on sp__who to public
go

