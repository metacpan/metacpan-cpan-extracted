select d.NAME,f.PHYRDS,f.PHYWRTS,
f.PHYBLKRD,f.PHYBLKWRT,f.READTIM,f.WRITETIM
from v$filestat f,v$datafile d
where f.FILE# = d.FILE#
order by d.NAME
