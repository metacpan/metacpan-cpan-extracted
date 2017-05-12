echo "Configuration Program For Sybase System 492 or 11"
echo "This is a basic batch program that might need editing"
echo ""
echo "Usage %0 USER PASSWORD SERVER"
echo ""
echo "In other words, you cant run this from windows by clicking on it!"
pause

isql -U%1 -P%2 -S%3 -iauditdb.492
isql -U%1 -P%2 -S%3 -iauditopt.492
isql -U%1 -P%2 -S%3 -iauditsecurity.492
isql -U%1 -P%2 -S%3 -ibadindex.492
isql -U%1 -P%2 -S%3 -iblock.492
isql -U%1 -P%2 -S%3 -icolconflict.492
isql -U%1 -P%2 -S%3 -icollist.492
isql -U%1 -P%2 -S%3 -icolnull.492
isql -U%1 -P%2 -S%3 -ihelpcolumn.492
isql -U%1 -P%2 -S%3 -ihelpindex.492
isql -U%1 -P%2 -S%3 -ihelplogin.492
isql -U%1 -P%2 -S%3 -ihelpprotect.492
isql -U%1 -P%2 -S%3 -ilock.492
isql -U%1 -P%2 -S%3 -ilockt.492
isql -U%1 -P%2 -S%3 -irevindex.492
isql -U%1 -P%2 -S%3 -irevtable.492
isql -U%1 -P%2 -S%3 -isyntax.492
isql -U%1 -P%2 -S%3 -iwhodo.492
isql -U%1 -P%2 -S%3 -ibcp.sql
isql -U%1 -P%2 -S%3 -icheckkey.sql
isql -U%1 -P%2 -S%3 -idate.sql
isql -U%1 -P%2 -S%3 -idatediff.sql
isql -U%1 -P%2 -S%3 -idbspace.sql
isql -U%1 -P%2 -S%3 -idepends.sql
isql -U%1 -P%2 -S%3 -idiskdevice.sql
isql -U%1 -P%2 -S%3 -idumpdevice.sql
isql -U%1 -P%2 -S%3 -ifind_msg_idx.sql
isql -U%1 -P%2 -S%3 -iflowchart.sql
isql -U%1 -P%2 -S%3 -iget_error.sql
isql -U%1 -P%2 -S%3 -igrep.sql
isql -U%1 -P%2 -S%3 -igroupprotect.sql
isql -U%1 -P%2 -S%3 -ihelpdbdev.sql
isql -U%1 -P%2 -S%3 -ihelpdefault.sql
isql -U%1 -P%2 -S%3 -ihelpgroup.sql
isql -U%1 -P%2 -S%3 -ihelpmirror.sql
isql -U%1 -P%2 -S%3 -ihelpproc.sql
isql -U%1 -P%2 -S%3 -ihelprule.sql
isql -U%1 -P%2 -S%3 -ihelpsegment.sql
isql -U%1 -P%2 -S%3 -ihelptable.sql
isql -U%1 -P%2 -S%3 -ihelptext.sql
isql -U%1 -P%2 -S%3 -ihelptrigger.sql
isql -U%1 -P%2 -S%3 -ihelpuser.sql
isql -U%1 -P%2 -S%3 -ihelpview.sql
isql -U%1 -P%2 -S%3 -iid.sql
isql -U%1 -P%2 -S%3 -iindexspace.sql
isql -U%1 -P%2 -S%3 -iiostat.sql
isql -U%1 -P%2 -S%3 -iisactive.sql
isql -U%1 -P%2 -S%3 -ils.sql
isql -U%1 -P%2 -S%3 -inoindex.sql
isql -U%1 -P%2 -S%3 -iobjprotect.sql
isql -U%1 -P%2 -S%3 -iproclib.sql
isql -U%1 -P%2 -S%3 -iqspace.sql
isql -U%1 -P%2 -S%3 -iread_write.sql
isql -U%1 -P%2 -S%3 -irevalias.sql
isql -U%1 -P%2 -S%3 -irevdb.sql
isql -U%1 -P%2 -S%3 -irevdevice.sql
isql -U%1 -P%2 -S%3 -irevgroup.sql
isql -U%1 -P%2 -S%3 -irevlogin.sql
isql -U%1 -P%2 -S%3 -irevmirror.sql
isql -U%1 -P%2 -S%3 -irevsegment.sql
isql -U%1 -P%2 -S%3 -irevuser.sql
isql -U%1 -P%2 -S%3 -isegment.sql
isql -U%1 -P%2 -S%3 -isize.sql
isql -U%1 -P%2 -S%3 -istat.sql
isql -U%1 -P%2 -S%3 -itrigger.sql
isql -U%1 -P%2 -S%3 -ivdevno.sql
isql -U%1 -P%2 -S%3 -iwho.sql
isql -U%1 -P%2 -S%3 -iwhoactive.sql

isql -U%1 -P%2 -S%3 -ihelpobject.sql
isql -U%1 -P%2 -S%3 -ihelpdb.492
isql -U%1 -P%2 -S%3 -ihelp.sql
isql -U%1 -P%2 -S%3 -ihelpdevice.sql
isql -U%1 -P%2 -S%3 -iserver.sql
isql -U%1 -P%2 -S%3 -irecord.492
isql -U%1 -P%2 -S%3 -iquickstats.492
