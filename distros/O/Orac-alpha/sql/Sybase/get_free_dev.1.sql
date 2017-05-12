		select device_name = sd.name, (sd.high - sd.low + 1)  / 512 - sum(su.size) / 512
		from master.dbo.sysdevices sd, master.dbo.sysusages su
		where sd.cntrltype = 0
		  and su.vstart between sd.low and sd.high
		group by sd.name
		having  ((sd.high - sd.low + 1)  / 512 - sum(su.size) / 512) > 0
		UNION
		select distinct device_name = sd.name, (sd.high - sd.low + 1)  / 512
		from master.dbo.sysdevices sd
		where sd.cntrltype = 0
		  and not exists (
				    select * from master.dbo.sysusages 
				    where vstart between sd.low and sd.high
				  )
		group by sd.name
		order by sd.name
