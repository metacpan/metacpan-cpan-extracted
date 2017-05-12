/* Procedure copyright(c) 1995 by Edward M Barlow */

/************************************************************************\ 
|* Procedure Name:	sp__helpsegment					*|
\************************************************************************/ 

:r database
go
:r dumpdb
go

if exists (select *
           from   sysobjects
           where  type = "P"
           and    name = "sp__helpsegment")
begin
    drop proc sp__helpsegment
end
go

/* Recieved by ed barlow from sybase */
create proc sp__helpsegment ( @segname char(30) = NULL, @dont_format char(1)=null )
as

set nocount on

if @dont_format is not null
begin
print "Segment Codes:"
print "  U=USER-defined segment on this device fragment"
print "  L=Database LOG may be placed on this device fragment"
print "  D=Database objects may be placed on this device fragment by DEFAULT"
print "  S=SYSTEM objects may be placed on this device fragment"
print ""

print "******* SERVER SEGMENT MAP *******"
end

select db=substring(db_name(usg.dbid),1,15),
       usg.segmap,
		 segname=isnull(substring(s.name,1,15),""),
       segs = substring(" U",sign(usg.segmap/8)+1,1) +
              substring(" L",(usg.segmap & 4)/4+1,1) +
              substring(" D",(usg.segmap & 2)/2+1,1) +
              substring(" S",(usg.segmap & 1)+1,1),
       "device name"=substring(dev.name,1,15),
		 "size (MB)" = str(usg.size/512.,7,2)
from master.dbo.sysusages usg,
     master.dbo.sysdevices dev,
	  syssegments s
where vstart between low and high
  and cntrltype = 0
  and isnull(@segname,s.name)=s.name
  and	usg.segmap & power(2,s.segment) = power(2,s.segment)
order by db_name(usg.dbid),lstart

go

/* Give execute privilege to users. This can be removed if you only want
   the sa to have excute privilege on this stored proc */
grant exec on sp__helpsegment to public
go
