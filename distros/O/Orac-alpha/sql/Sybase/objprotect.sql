/* Procedure copyright(c) 1997 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__objprotect.sql
**
**   permissions by object vs sel/upd/ins/del
**
**   optionally can pass in user or group and it will filter
**
**   only works on full table info (not on column stuff)
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__objprotect"
           and    type = "P")
begin
   drop proc sp__objprotect
end
go

create procedure sp__objprotect( @username char(30) = NULL,@dont_format char(1) = NULL )
as
set nocount on

select uid
into   #good_uids
from   sysusers
where  ( uid=gid and @username is null )
or     ( name = @username )

select name,id,type,s=0,u=0,d=0,i=0,r=0,e=0
into   #objects
from   sysobjects

update 	#objects set s=( select count(*)
from 	sysprotects p,  #good_uids g
where 	o.id=p.id
and 	p.action=193
and 	isnull(columns,0x01) = 0x01
and 	protecttype<=1
and 	g.uid = p.uid )
from #objects o

update #objects set u=( select count(*)
from sysprotects p,  #good_uids g
where o.id=p.id
and p.action=197
and isnull(columns,0x01) = 0x01
and protecttype<=1
and g.uid = p.uid )
from #objects o

update #objects set d=( select count(*)
from sysprotects p,  #good_uids g
where o.id=p.id
and p.action=196
and isnull(columns,0x01) = 0x01
and protecttype<=1
and g.uid = p.uid )
from #objects o

update #objects set i=( select count(*)
from sysprotects p,  #good_uids g
where o.id=p.id
and p.action=195
and isnull(columns,0x01) = 0x01
and protecttype<=1
and g.uid = p.uid )
from #objects o

update #objects set e=( select count(*)
from sysprotects p,  #good_uids g
where o.id=p.id
and p.action=224
and isnull(columns,0x01) = 0x01
and protecttype<=1
and g.uid = p.uid )
from #objects o

update #objects set r=( select count(*)
from sysprotects p,  #good_uids g
where o.id=p.id
and isnull(columns,0x01) = 0x01
and protecttype=2
and g.uid = p.uid )
from #objects o

select name,type, sel=convert(char(6),s),upd=convert(char(6),u),del=convert(char(6),d),ins=convert(char(6),i),rev=convert(char(6),r),exe=convert(char(6),e)
from #objects
order by type,name

return (0)
go
grant execute on sp__objprotect to public
go
