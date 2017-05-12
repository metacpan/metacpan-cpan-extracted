/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:      sp__qspace                                     *|
|*                                                                      *|
|* Author:              EMB                                       *|
|*                                                                      *|
|* Description:         Database/log space available/used/utilised      *|
|*                                                                      *|
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__qspace")
begin
    drop proc sp__qspace
end
go

create procedure sp__qspace ( @dont_format char(1) = null )
as
begin

declare @log_pgs  float
declare @used_pgs float
declare @pct_used float
declare @db_size  float,@log_size float
declare @scale 	float /* for overflow */

set nocount on

select @db_size = sum(size), @log_size=0
        from master.dbo.sysusages u
                where u.dbid = db_id()
                and   u.segmap != 4

/* Just log */
select @log_size = sum(size)
        from master.dbo.sysusages u
                where u.dbid = db_id()
                and   u.segmap = 4

/* select id,doampg,ioampg  */
/* into #tmp from sysindexes */

select @log_pgs = reserved_pgs(i.id, doampg)
from sysindexes i
where i.id = 8

select @used_pgs = sum(reserved_pgs(id, doampg) + reserved_pgs(id, ioampg))
from sysindexes
where id != 8

/* Reset If Data & Log On Same Device */
if @log_size is null
        select @used_pgs = @used_pgs+@log_pgs,@log_pgs=0, @log_size=1

if @log_size = 0
	select @log_size = @log_size + 1

select @pct_used=(@used_pgs*100)/@db_size

select  Name 	   = db_name(),
        Percent    = @pct_used,
        "Log Pct"  = (@log_pgs*100)/@log_size
end
go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have execute privilege on this stored proc */
grant exec on sp__qspace to public
go
