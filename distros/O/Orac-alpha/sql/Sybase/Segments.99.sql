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
  and isnull("%s",s.name)=s.name
  and usg.dbid = db_id("%s")
  and   usg.segmap & power(2,s.segment) = power(2,s.segment)
order by db_name(usg.dbid),lstart

