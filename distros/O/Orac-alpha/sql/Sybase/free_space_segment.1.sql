select total_size = convert(varchar(20),
        round((sum(u.size) *  0.001953), 0)) + "MB",
        total_pages = sum(u.size),
        free_pages = sum(curunreservedpgs(db_id(), u.lstart, u.unreservedpgs)),
        used_pages = sum(u.size) - sum(curunreservedpgs(db_id(), u.lstart, u.unreservedpgs)),
        free_Mb =  round((sum(curunreservedpgs(db_id(), u.lstart, u.unreservedpgs))/512), 0),
        free_Pct = 100 * convert(float, sum(curunreservedpgs(db_id(), u.lstart, u.unreservedpgs))) /  convert(float, sum(u.size)),
        used_Mb = round((sum(u.size) - sum(curunreservedpgs(db_id(), u.lstart, u.unreservedpgs)))/512, 0),
        used_Pct = 100 * convert(float,(sum(u.size) - sum(curunreservedpgs(db_id(), u.lstart, u.unreservedpgs)))) / convert(float, sum(u.size))
from master.dbo.sysusages u, master.dbo.sysdevices d
where u.segmap & power(2,1) = power(2,1)
        and u.dbid = db_id()
        and d.status & 2 = 2
        and d.low <= u.vstart
        and d.high >= u.vstart + (u.size - 1)
