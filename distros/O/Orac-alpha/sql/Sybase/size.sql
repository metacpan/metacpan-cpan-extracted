:r database
go
:r dumpdb
go

/*
**
** This proc was sent to me by Michael A van Stolk.  Im not sure if he wrote
** it or what, but it is useful.
**
** Description: This stored procedure prints out information regarding the size
**              of the specified stored procedure or all stored procedures if
**              none is specified.
                        
 Utility sp__size 

 Proc_name                      Size    Avail_size  Lines       Avail_lines 
 ------------------------------ ------- ----------- ----------- ----------- 
 acsectype_valid                2    KB         126           1         254 
 addusr                         7    KB         121           4         251 
 AllABA                         1    KB         127           1         254 
 AllSyndMgmtGrps                3    KB         125           1         254 
 APGenTrade                     16   KB         112           9         246 
 Assign_Lineno                  4    KB         124           3         252 
 AuditReport                    12   KB         116           6         249 
 AutoFX_Insert                  33   KB          95          28         227 
 AvgPriceWO                     28   KB         100           9         246 
 BadFlags                       5    KB         123           2         253 
 BJGenTrade                     31   KB          97          17         238 
 BreakLink                      5    KB         123           2         253 
 Cancel                         2    KB         126           2         253 
 CancelTicket                   3    KB         125           2         253 
 CancelTrade                    3    KB         125           2         253 
 Cancel_SDTS_Trade              4    KB         124           2         253 
 Cancel_Ticket                  35   KB          93          35         220 
 Cancel_Trade                   35   KB          93          29         226 
 CheckAccess                    2    KB         126           1         254 
 CheckBreakOutExists            8    KB         120           5         250 
 Update_SDTS_ForexLink          5    KB         123           3         252 
 Update_SDTS_Interest           8    KB         120           6         249 
 Update_SDTS_Trade              92   KB          36         101         154 
 Update_Userid                  11   KB         117           8         247 
 UserList                       12   KB         116           7         248 
 XferDelBrkr                    10   KB         118           7         248 
 XferDelCust                    13   KB         115          10         245 
 XferDelFirm                    13   KB         115          11         244 

**
*/
if (select object_id("sp__size")) > 0 
	drop proc sp__size
go


create proc sp__size (@objname varchar(40) = 'ALL')
as

declare	@size	int,
    	@lines	int,
    	@pid	int,
    	@msg	varchar(76)

select	name,
    	id,
    	size	= 0,
    	lines	= 0
    into    #procs
    from    sysobjects
    where   type = 'P' and (@objname = 'ALL' or name = @objname)

if @@rowcount = 0
    begin
    select  @msg = 'Proc ' + @objname + ' not found in database ' + db_name()
    print @msg
    return 1
    end

select	@pid = min(id) from #procs
while (@pid is not null)
    begin
    select  @size = 255 * count(*) from sysprocedures
    	where	id = @pid
    select  @lines = count(*) from syscomments
    	where	id = @pid
    update #procs
    	set size    = @size,
    	    lines   = @lines
    	where	id = @pid
    select  @pid = min(id)
    	from	#procs
    	where	id > @pid
    end

select	Proc_name   = name,
    	Size	    = convert(char(5),size / 1000) + "KB",
    	Avail_size  = 128 - (size / 1000),
    	Lines	    = lines,
    	Avail_lines = 255 - lines
    from    #procs
    order by upper(name)

return 0
go

grant execute on sp__size to public
go


