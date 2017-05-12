/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:      sp__dbspace                                     *|
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
           and    name = "sp__dbspace")
begin
    drop proc sp__dbspace
end
go

create procedure sp__dbspace ( @dont_format char(1) = null )
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

select id,doampg,ioampg into #tmp from sysindexes

select @log_pgs = reserved_pgs(i.id, doampg)
from #tmp i
where i.id = 8

select @used_pgs = sum(reserved_pgs(id, doampg) + reserved_pgs(id, ioampg))
from #tmp
where id != 8

/* @scale is number way to convert from pages to K  */
/* for example -> normally 2K page size so @scale=2 and multipled results */
select 	@scale=d.low/1024
from  	master.dbo.spt_values d
where 	d.number = 1 and d.type = "E"
having 	d.number = 1 and d.type = "E"

/* Reset If Data & Log On Same Device */
if @log_size is null
begin
        select @used_pgs = @used_pgs+@log_pgs,@log_pgs=0,@log_size=0
end

select @pct_used=(@used_pgs*100)/@db_size

select  Name 	  	 = convert(char(12),db_name()),
        "Data MB"  = str((@db_size*@scale)/1024, 13, 0),
        "Used MB"  = str((@used_pgs*@scale)/1024, 14, 1),
        Percent    = str(@pct_used, 7, 2),
        "Log MB"   = str((@log_size*@scale)/1024, 9, 0),
        "Log Used" = str((@log_pgs*@scale)/1024, 9, 2),
        "Log Pct"  = str((@log_pgs*100)/(@log_size+1), 7, 2)
end
go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have execute privilege on this stored proc */
grant exec on sp__dbspace to public
go
