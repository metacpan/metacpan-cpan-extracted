/* Procedure copyright(c) 1995 by Edward M Barlow */

/******************************************************************************
**
** Name        : sp__groupprotect.sql
**
**   permissions by object type / user group vs sel/upd/ins/del
**
******************************************************************************/
:r database
go
:r dumpdb
go

if exists (select * from sysobjects
           where  name = "sp__groupprotect"
           and    type = "P")
begin
   drop proc sp__groupprotect
end
go

create procedure sp__groupprotect( @dont_format char(1) = NULL )
as
set nocount on

select distinct type,uid=sysusers.uid,group_name=sysusers.name,total=0,s=0,u=0,d=0,i=0,r=0,e=0
into   #objects
from   sysusers,   sysobjects
where  sysusers.uid=sysusers.gid
and    sysobjects.uid=1
and    ( sysusers.uid>=16390 or sysusers.uid < 16000 )

select distinct action,id,uid,protecttype,type="  "
into  #p
from  sysprotects p

update  #p
set     type=o.type
from    sysobjects o
where   o.id=#p.id
and     o.uid=1

update #objects set total=(select count(*) from sysobjects o
				where o.type=n.type
				and    o.uid=1)
from #objects n

update  #objects
set     s=(select count(*)
                from    #p
                where   #p.action=193
		and     #p.uid = #objects.uid
                and     #p.protecttype<=1
                and     #p.type = #objects.type
)
from #objects

update  #objects
set     u=(select count(*)
                from    #p
                where   #p.action=197
		and     #p.uid = #objects.uid
                and     #p.protecttype<=1
                and     #p.type = #objects.type
)
from #objects

update  #objects
set     d=(select count(*)
                from    #p
                where   #p.action=196
		and     #p.uid = #objects.uid
                and     #p.protecttype<=1
                and     #p.type = #objects.type
)
from #objects

update  #objects
set     i=(select count(*)
                from    #p
                where   #p.action=195
		and     #p.uid = #objects.uid
                and     #p.protecttype<=1
                and     #p.type = #objects.type
)
from #objects

update  #objects
set     r=(select count(*)
                from    #p
                where   #p.protecttype=2
		and     #p.uid = #objects.uid
                and     #p.type = #objects.type
)
from #objects

update  #objects
set     e=(select count(*)
                from    #p
                where   #p.action=224
		and     #p.uid = #objects.uid
                and     #p.protecttype<=1
                and     #p.type = #objects.type
)
from #objects

if @dont_format is null
begin
	select type,grp=convert(char(15),group_name),tot=convert(char(6),total),sel=convert(char(6),s),upd=convert(char(6),u),del=convert(char(6),d),ins=convert(char(6),i),rev=convert(char(6),r),exe=convert(char(6),e)
	from #objects
	order by type,group_name
end
else
begin
	select type,grp=group_name,tot=convert(char(6),total),sel=convert(char(6),s),upd=convert(char(6),u),del=convert(char(6),d),ins=convert(char(6),i),rev=convert(char(6),r),exe=convert(char(6),e)
	from #objects
	order by type,group_name
end

return (0)
go
grant execute on sp__groupprotect to public
go
