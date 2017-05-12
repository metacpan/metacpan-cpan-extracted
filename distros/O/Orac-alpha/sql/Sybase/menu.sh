#!/bin/sh
#--------------------------------------------------------------------
# Set SQL Server, Login, Password, databases in SQL Server, ISQL_ARGS
#--------------------------------------------------------------------

set_server()
{

# Read out all entries in the interfaces file
# and present three entries on each row in columns

echo "\nSybase Servers defined in $SYBASE/interfaces\n"
egrep "^[A-Za-z0-9]" $SYBASE/interfaces \
| sort \
| awk '{print $1 "@@@@@@@@@@@@@@@@@@@@@@@@@"}' \
| cut -c1-26 \
| xargs -n3 -x echo \
| tr '@' ' '

if [ ! -r $SYBASE/interfaces ]; then
   echo "Set \$SYBASE correct and try again.\n"
   exit 1
fi

# Let the user choose SQL Server, Use $DSQUERY or SYBASE as default

echo
echo "SQL Server [ ${DSQUERY:=SYBASE} ] : \c"
read answer
DSQUERY=${answer:-$DSQUERY}
: ${DSQUERY:=SYBASE}
if [ "$answer" = exit -o "$answer" = quit ]; then rm -f $input $output; exit; fi

# Check if configuration file exists then use that file
# Configuration file must be located under $SYBDIR/.$DSQUERY
# Otherwise ask for password and user in that SQL Server
# Export all variables
# If I do run as sybase I normally login as sa

db=master
echo "Database is set to master"

if [ -f ${CONF_PREFIX}$DSQUERY ]; then
   . ${CONF_PREFIX}$DSQUERY
else
   if [ "$USER" = "sybase" ]; then USER=sa; fi
   echo "Sybase User Login [ ${USER:=sa} ] : \c"
   read answer
   USER=${answer:-$USER}
   if [ "$answer" = exit -o "$answer" = quit ]; then exit; fi
   echo "Password : \c"
   stty -echo
   read answer
   stty echo
   echo
   USER_PW=${answer:-$USER_PW}
fi

# Append $SYBASE/bin to path but no longer PATH than necessary

PATH=$SYBASE/bin:`echo ":${PATH}:" | sed "s+:$SYBASE/bin:+:+" | sed 's/:$//'`

export DSQUERY USER SYBASE PATH

# Get all databases in that SQL Server

sql="select name from master..sysdatabases"
databases=`run_sql | sed '1,3d'`

# Check for warnings when server on another platform than your client
# I have yet only needed this when client is on HP-UX and server on Sun
# here add you own incompatibilities

if [ `echo $databases | egrep -c 'character set'` -gt 0 ]; then
   if [ `uname` = HP-UX ]; then
      ISQL_ARGS='-J iso_1'
   else
      ISQL_ARGS='-J roman8'
   fi
   export ISQL_ARGS
   sql="select name from sysdatabases"
   databases=`run_sql | sed '1,3d'`
fi

if [ `echo $databases | egrep -c '^Msg |DB-LIBRARY error'` -gt 0 ]; then
   echo "$databases\n"; set_server
fi

get_version
}

#--------------------------------------------------------------------
# set_database
#--------------------------------------------------------------------

set_database()
{
   echo
   echo "$databases"
   echo
   echo "Database: \c"
   read db
}

#--------------------------------------------------------------------
# Check version of SQL Server
#--------------------------------------------------------------------

get_version()
{
version=`echo "$USER_PW\ngo\nselect value from master..sysconfigures where config = 122\ngo" | isql $ISQL_ARGS | egrep '[0-9]'`
version=`echo $version | cut -c1-2`
if [ ! "$version" ]; then
   echo "\nCould not decide SQL Server version"
   echo "$USER_PW\ngo\nselect value from master..sysconfigures where config = 122\ngo" | isql $ISQL_ARGS | tail +3
fi
}

#--------------------------------------------------------------------
# Run single isql command in system10 or system11
#--------------------------------------------------------------------

run_sql_10()
{
echo

if [ "`echo $version | cut -c1`" != 1 ]; then
   echo "This SQL Server is not running System 10 or newer"
   return
fi
echo "set nocount on\ngo\nuse $db\ngo\n$sql\ngo" > $input
echo $USER_PW | isql $ISQL_ARGS -w 2000 -i $input \
| sed '1d' | egrep -v 'return status' | tee $output
}

#--------------------------------------------------------------------
# Run single isql command in system11
#--------------------------------------------------------------------

run_sql_11()
{
echo
if [ "$version" != 11 ]; then
   echo "This SQL Server is not running System 11"
   return
fi
echo "set nocount on\ngo\nuse $db\ngo\n$sql\ngo" > $input
echo $USER_PW | isql $ISQL_ARGS -w 2000 -i $input \
| sed '1d' | egrep -v 'return status' | tee $output
}

#--------------------------------------------------------------------
# Run single isql command
#--------------------------------------------------------------------

run_sql()
{
   echo
   echo "set nocount on\ngo\nuse $db\ngo\n$sql\ngo" > $input
   echo $USER_PW | isql $ISQL_ARGS -w 2000 -i $input | sed '1d' | egrep -v 'return status' | tee $output
}

#--------------------------------------------------------------------
# Run isql command on all databases
#--------------------------------------------------------------------

run_sql_all_db()
{
   echo
   echo "set nocount on\ngo" > $input
   for database in $databases; do
      echo "print '\n$database'\ngo\nuse $database\ngo\n$sql\ngo" >> $input
   done
   echo $USER_PW | isql $ISQL_ARGS -w 2000 -i $input | sed '1d' | egrep -v 'return status' | tee $output
}

#--------------------------------------------------------------------
# Run isql command on all objects of certain type
#--------------------------------------------------------------------

run_sql_objects()
{
   echo
   echo "set nocount on\ngo\nuse $db\ngo" > $input
   if [ "$objects" ]; then
      echo $objects | awk "{print $sql}" >> $input
   else
      echo "$USER_PW\nset nocount on\ngo\nuse $db\ngo\n
      select name from sysobjects where type like '$type'\ngo\n" \
      | isql $ISQL_ARGS | sed '1,3d' | egrep -v 'return status|^[       ]*$' | awk "{print $sql}" >> $input
   fi
   echo "go" >> $input
   echo $USER_PW | isql $ISQL_ARGS -w 2000 -i $input | egrep -v 'return status|^sp_[a-z]' | tee $output
}

#--------------------------------------------------------------------
# Run reverse engineering to its edge
#--------------------------------------------------------------------

copy_out_all_defs()
{
   echo
   dbdir=$DBDIR/$DSQUERY.$db
   if [ ! -d $dbdir ]; then mkdir -p $dbdir; fi
   if [ "$db" = master ]; then
      echo "Copying out databases"
      sql=sp__revdb; run_sql >/dev/null; tail +3 $output >$dbdir/databases.sql
      echo "Copying out devices"
      sql=sp__revdevice; run_sql >/dev/null; tail +3 $output >$dbdir/devices.sql
      echo "Copying out logins"
      sql=sp__revlogin; run_sql >/dev/null; tail +3 $output >$dbdir/logins.sql
      echo "Copying out mirrors"
      sql=sp__revmirror; run_sql >/dev/null; tail +3 $output >$dbdir/mirrors.sql
   fi
   echo "Copying out aliases"
   sql=sp__revalias; run_sql >/dev/null; tail +3 $output >$dbdir/aliases.sql
   echo "Copying out groups"
   sql=sp__revgroup; run_sql >/dev/null; tail +3 $output >$dbdir/groups.sql
   echo "Copying out indexes"
   sql=sp__revindex; run_sql >/dev/null; tail +3 $output >$dbdir/indexes.sql
   echo "Copying out segments"
   sql=sp__revsegment; run_sql >/dev/null; tail +3 $output >$dbdir/segments.sql
   echo "Copying out users"
   sql=sp__revuser; run_sql >/dev/null; tail +3 $output >$dbdir/users.sql
   echo "Copying out tables"
   objects=; type=U; objectstype=table
   sql='"exec sp__revtable", $1'; run_sql_objects >/dev/null; tail +2 $output >$dbdir/tables.sql
   echo "Copying out procedures"
   objects=; type=P; objectstype=procedure
   sql='"exec sp__helptext", $1'; run_sql_objects >/dev/null; tail +2 $output >$dbdir/procedures.sql
   echo "Copying out views"
   objects=; type=V; objectstype=view
   sql='"exec sp__helptext", $1'; run_sql_objects >/dev/null; tail +2 $output >$dbdir/views.sql
   echo "Copying out rules"
   objects=; type=R; objectstype=rule
   sql='"exec sp__helptext", $1'; run_sql_objects >/dev/null; tail +2 $output >$dbdir/rules.sql
   echo "Copying out triggers"
   objects=; type=TR; objectstype=trigger
   sql='"exec sp__helptext", $1'; run_sql_objects >/dev/null; tail +2 $output >$dbdir/triggers.sql
   echo "Copying out defaults"
   objects=; type=D; objectstype=default
   sql='"exec sp__helptext", $1'; run_sql_objects >/dev/null; tail +3 $output >$dbdir/defaults.sql

   echo "Copying out permissions"
   sql="sp_helprotect $object"
   run_sql \
   | awk '{print $3, $4, "on", $1 "." $5, "(", $6, ") to", $2, $7}' \
   | sed 's/( All )//' | sed 's/FALSE$//' | sed 's/TRUE$/with grant option/' | tail +4 >$dbdir/grants.sql

   echo "Copying type definitions"
   sql='select "exec sp_addtype ", "@"+t.name+"@", ",", "@"+t2.name, "(", t.length, ")", "(", t.prec ,",",  t.scale, ")", t.ident, t.allownulls
        from systypes t, systypes t2 where t.type = t2.type and t.usertype > 100 and t2.usertype < 100'
   run_sql | tr ' @' ' "' | tr -s ' ' \
   | sed 's/( NULL , NULL ) //' | sed 's/, NULL )/)/' \
   | sed 's/0 $/"not null"/' | sed 's/1 $/"null"/' \
   | sed 's/) 1.*$/)", "identity"/' | sed 's/) 0/)",/' \
   | sed 's/( [0-9] ) (/(/' \
   | sed 's/\([a-z]*int\) ( [0-9] )/\1/' \
   | sed 's/bit ( [0-9] )/bit/' \
   | sed 's/timestamp ( [0-9] )/timestamp/' \
   | sed 's/\([a-z]datetime\) ( [0-9] )/\1/' \
   | sed 's/real ( [0-9] )/real/' \
   | sed 's/\(double precision\) ( [0-9] )/\1/' \
   | sed 's/\([a-z]*money\) ( [0-9] )/\1/' \
   | tail +4 >$dbdir/types.sql

   echo "\nNo copying of rule bindings are implemented in this version"
   echo "No copying of default bindings are implemented in this version"
   echo "No copying of sysservers are implemented in this version"
   echo "No copying of configuration are implemented in this version"
   echo "No copying of foreignkeys or primary keys are implemented in this version"
   echo "No copying of auditing is implemented in this version"
   echo "\nThis reverse engineering may lack more to be complete!!!\n"
}

#--------------------------------------------------------------------
# Run monitoring functions for SQL Server
#--------------------------------------------------------------------

monitor()
{
while true; do
   cat << EOB

   ?    Show all other menu choices that always are active
   0    Return to main menu
   1    View locks in server
   2    Check blocking processes
   3    List all processes
   4    List user processes
   5    Check who is doing something on server
   6    Run a loop on existing processes and print rows working
   7    Monitor a single process
   8    Check information about current cursors (N Sys10)
   9    Dump server monitoring information

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) sql=sp__lock; run_sql;;
   2) sql=sp__block; run_sql_all_db;;
   3) sql=sp__who; run_sql;;
   4) echo "Loginname [all] : \c"; read logins; : ${logins:=NULL}
      sql="sp__whodo $logins"; run_sql;;
   5) echo "Loginname [all] : \c"; read logins; : ${logins:=all}
      sql="sp__whoactive '$logins'"; run_sql;;
   6) echo "No of iterations: \c"; read iterations
      sql="sp__iostat $iterations"; run_sql;;
   7) echo "Sybasess Process ID (spid): \c"; read process; : ${process:=null}
      echo "Monitoring interval in seconds [5|10|20|60] : \c"; read time
      sql="sp__isactive $process, ${time:-5}"; run_sql;;
   8) sql="sp_cursorinfo -1"; run_sql_10;;
   9) sql=sp__quickstats; run_sql;;
   *) quickchoice;;
   esac
done
}
#--------------------------------------------------------------------
# Check allocations and devices
# Check devices, database and segment allocations
#--------------------------------------------------------------------

space()
{
while true; do
   cat << EOB

   ?    Show all other menu choices that always are active
   0    Return to main menu
   1    List all devices
   2    List single device
   3    List dump devices
   4    List disk devices
   5    Show mirror information
   6    Who's who in the device world
   7    Show how Databases use Devices
   8    Summary of current database space
   9    List all databases
   A    Detailed info on all databases
   B    Detailed info on current database
   C    Segment information (db allocations)
   D    Segment Information (table allocations)
   E    Server summary report

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) sql=sp__helpdevice; run_sql;;
   2) echo "Device: \c"; read device
      sql="sp__diskdevice $device"; run_sql;;
   3) sql=sp__dumpdevice; run_sql;;
   4) sql=sp__diskdevice; run_sql;;
   5) sql=sp__helpmirror; run_sql;;
   6) sql=sp__vdevno; run_sql;;
   7) sql=sp__helpdbdev; run_sql;;
   8) sql=sp__dbspace; run_sql;;
   9) sql=sp__helpdb; run_sql;;
   a|A) sql=sp__helpdb; run_sql_all_db;;
   b|B) sql=sp__helpdb; run_sql;;
   c|C) sql=sp__helpsegment; run_sql;;
   d|D) sql=sp__segment; run_sql;;
   e|E) sql=sp__server; run_sql;;
   *) quickchoice;;
   esac
done
}

#--------------------------------------------------------------------
# Check Access
# Check logins, users, groups
#--------------------------------------------------------------------

users()
{
while true; do
   cat << EOB

   ?    Show all other menu choices that always are active
   0    Return to main menu
   1    Show logins and remote logins to server
   2    Show remote access (N)
   3    Display information about a login account (N Sys11)
   4    Show all locked accounts (N Sys10)
   5    List users in current database by group
   6    Help on groups in current database
   7    Report statistics on system usage for all or single user (N Sys10)

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) sql=sp__helplogin; run_sql;;
   2) sql="sp_helpserver\ngo\nsp_helpremotelogin"; run_sql | cut -c1-120;;
   3) echo "Login account: \c"; read login
      sql="sp_displaylogin $login"; run_sql_11;;
   4) sql=sp_locklogin; run_sql_10;;
   5) sql=sp__helpuser; run_sql;;
   6) sql=sp__helpgroup; run_sql;;
   7) echo "Login: \c"; read login
      sql="sp_reportstats $login"; run_sql_10;;
   *) quickchoice;;
   esac
done
}

#--------------------------------------------------------------------
# List objects, tables, views, rules, defaults, index
#--------------------------------------------------------------------

list_objects()
{
while true; do
   cat << EOB

   1 List all columns in current database
   2 List all objects in current database
   3 List all tables in current database
   4 List all views in current database
   5 List all defaults in current database
   6 List all rules in current database
   7 List all triggers in current database
   8 List all procedures in current database
   9 List all indexes
   A Space used by indexes in database
   B List badly formed indexes
   C List all tables missing index
   D List tables by # procs that read # that write # do both
   E Useful trigger schema
   F List all objects including given string

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) sql=sp__collist; run_sql;;
   2) sql=sp__helpobject; run_sql;;
   3) sql=sp__helptable; run_sql;;
   4) sql=sp__helpview; run_sql;;
   5) sql=sp__helpdefault; run_sql;;
   6) sql=sp__helprule; run_sql;;
   7) sql=sp__helptrigger; run_sql;;
   8) sql=sp__helpproc; run_sql;;
   9) sql=sp__helpindex; run_sql;;
   a|A) sql=sp__indexspace; run_sql;;
   b|B) sql=sp__badindex; run_sql;;
   c|C) sql=sp__noindex; run_sql;;
   d|D) sql=sp__read_write; run_sql;;
   e|E) sql=sp__trigger; run_sql;;
   f|F) echo "String: \c"; read string
        sql="sp__ls '$string'"; run_sql;;
   *) quickchoice;;
   esac
done
}

#--------------------------------------------------------------------
# Help on objects, i e tables, procs, triggers, views, rules, defaults
#--------------------------------------------------------------------

info_on_objects()
{
while true; do
   cat << EOB

   TYPE OF OBJECT

   1 Default(s)
   2 Procedure(s)
   3 Rule(s)
   4 Table(s)
   5 Trigger(s)
   6 View(s)
   7 Show likely join candidates between two tables (N Sys11)
   8 Check constraints for a table (N Sys11)
   9 Show the query processing mode of a procedure, view or trigger (N Sys11)
   A Show the transaction mode associated with procedures

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1|D*) type=D; objecttype=default;;
   2|P*) type=P; objecttype=procedure;;
   3|R*) type=R; objecttype=rule;;
   4|Ta*) type=U; objecttype=table;;
   5|Tr*) type=TR; objecttype=trigger;;
   6|V*) type=V; objecttype=view;;
   7) sql="select name from sysobjects where type = \"U\""; run_sql
      echo "\nTable1: \c"; read table1
      echo "Table2: \c"; read table2
      sql="sp_helpjoins $table1, table2"; run_sql_11; continue;;
   8) sql="select name from sysobjects where type = \"U\""; run_sql
      echo "\nTable: \c"; read table
      sql="sp_helpconstraint $table, detail"; run_sql_11; continue;;
   9) echo "Procedure/Trigger/View: \c"; read object; ${object:=null}
      sql="sp_procqmode $object, detail"; run_sql_11; continue;;
   a|A) sql="sp_procxmode"; run_sql; continue;;
   *) quickchoice;;
   esac

   sql="select name from sysobjects where type = \"$type\""; run_sql

   echo "\n$objecttype: [ "" = all ] \c"; read objects

   cat << EOB

   1 Get detailed type independent help on $objecttype
   2 Get detailed type dependent help on $objecttype
   3 Get text for object
   4 Get dependencies
   5 Create unix script that will drop object
   6 Makes a flowchart of procedure nesting
   7 Show indexes by table
   8 Show columns by table
   9 Show privileges on object (N)
EOB
   echo "\nChoose: \c"
   read answer
   sqlend=
   case "$answer" in
   ""|0) break;;
   1) sql='"exec sp__help",$1'; run_sql_objects;;
   2) sql='"exec sp__help'${objecttype}'" , $1'; run_sql_objects;;
   3) sql='"exec sp__helptext", $1'; run_sql_objects;;
   4) sql='"exec sp__depends", $1'; run_sql_objects;;
   5) sql='"exec sp__depends", $1, ", \"drop\""'; run_sql_objects;;
   6) sql='"print \"", $1, "\"\n exec sp__flowchart", $1'
      ( type=P; objecttype=procedure; run_sql_objects ) ;;
   7) sql='"exec sp__helpindex", $1'
      ( type=U; objecttype=table; run_sql_objects ) ;;
   8) sql='"exec sp__helpcolumn", $1'
      ( type=U; objecttype=table; run_sql_objects ) ;;
   9) echo; sql="sp_helprotect $objects"; run_sql | egrep "Grant|Revoke" \
      | awk '{print $3, $4, "on", $1 "." $5, "(", $6, ") to", $2, $7}' \
      | sed 's/( All )//' | sed 's/FALSE$//' | sed 's/TRUE$/with grant option/';;
    *) quickchoice;;
     esac
done
}

#--------------------------------------------------------------------
# Find bad code
#--------------------------------------------------------------------

trouble()
{
while true; do
   cat << EOB

   ?    Show all other menu choices that always are active
   0    Main menu"
   1    Audit security on server
   2    Audit security on server (only errors)
   3    Audit current database for potential problems
   4    Generate script for referential integrity problems
   5    List badly formed indexes
   6    List all tables having no index

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) sql=sp__auditsecurity; run_sql;;
   2) sql="sp__auditsecurity 1"; run_sql;;
   3) sql=sp__auditdb; run_sql;;
   4) sql=sp__checkkey; run_sql;;
   5) sql=sp__badindex; run_sql;;
   6) sql=sp__noindex; run_sql;;
   *) quickchoice;;
   esac
done
}

#--------------------------------------------------------------------
# Reverse engineering and create script for logical dump / load
#--------------------------------------------------------------------

regenerate()
{
while true; do
   cat << EOB

   ?    Show all other menu choices that always are active
   0    Main menu
   1    Login generation script
   2    Device generation script
   3    Mirror generation script
   4    Database generation script
   5    Segment generation script
   6    Alias generation script
   7    User generation script
   8    Group generation script
   9    Table generation script
   A    Index generation script
   B    Create unix script to bcp in/out database
   C    Copy out MOST definitions in db to directory under $DBDIR (N)

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) sql=sp__revlogin; run_sql;;
   2) sql=sp__revdevice; run_sql;;
   3) sql=sp__revmirror; run_sql;;
   4) sql=sp__revdb; run_sql;;
   5) sql=sp__revsegment; run_sql;;
   6) sql=sp__revalias; run_sql;;
   7) sql=sp__revuser; run_sql;;
   8) sql=sp__revgroup; run_sql;;
   9) objects=; type=U; objectstype=table
      sql='"exec sp__revtable", $1'; run_sql_objects;;
   a|A) sql=sp__revindex; run_sql;;
   b|B) echo "Direction [Out|In] ? \c"
        read answer
        case $answer in
        I*|i*) sql="sp__bcp '$DSQUERY', '$db', '$USER_PW', 'in'"; run_sql
               cp $output $DBDIR/bcpin.$DSQUERY; chmod u+x $DBDIR/bcpin.$DSQUERY;;
        O*|o*) sql="sp__bcp '$DSQUERY', '$db', '$USER_PW', 'out'"; run_sql;
               cp $output $DBDIR/bcpout.$DSQUERY; chmod u+x $DBDIR/bcpout.$DSQUERY;;
        esac;;
   c|C) copy_out_all_defs;;
   *) quickchoice;;
   esac
done
}

#--------------------------------------------------------------------
# Miscellaneous functions
#--------------------------------------------------------------------

misc()
{
while true; do
   cat << EOB

   ?    Show all other menu choices that are always active
   0    Main menu
   1    List all date styles
   2    Check which dboptions that are possible to set (N)
   3    Search for a text in SQL Code in database
   4    Check language and sort order (N)
   5    Check configuration (N)
   6    Information about caches (N Sys11)
   7    Show all thresholds defined in database (N Sys10)

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) sql=sp__date; run_sql;;
   2) sql=sp_dboption; run_sql;;
   3) echo "\nSyntax for parameter: string_[{+-&}_string]+\n"
      echo "Example: calvin_&_hobbes"
      echo "Parameter: \c"; read parameter
      echo "Case sensitive [y|n] ? \c"; read sensitive
      case $sensitive in
      y*|Y*) sql="sp__grep '`echo $parameter | tr '_' ' '`', s"; run_sql;;
      n*|N*) sql="sp__grep '`echo $parameter | tr '_' ' '`', i"; run_sql;;
      esac;;
   4) sql="sp_helpsort\ngo\nsp_helplanguage"; run_sql;;
   5) if [ "$version" = 11 ]; then sql="sp_configure \"%\""; else sql=sp_configure; fi; run_sql;;
   6) sql=sp_helpcache; run_sql_11;;
   7) sql=sp_helpthreshold; run_sql_10 | cut -c1-80;;
   *) quickchoice;;
   esac
done
}

#--------------------------------------------------------------------
# Own sql scripts
#--------------------------------------------------------------------

own()
{
while true; do
   cat << EOB

   ?    Show all other menu choices that are always active
   0    Main menu
   1    Run SQL function (under $SQLDIR)
   2    Run script (under $SCRIPTDIR)

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   ""|0) break;;
   1) ls $SQLDIR && ( echo "\nChoose SQL to run: \c"; read input
      echo $USER_PW | isql $ISQL_ARGS -i $SQLDIR/$input | sed '1d' | egrep -v "return status" | tee $output ) ;;
   2) ls $SCRIPTDIR && (
      echo "\nChoose script to run: \c"; read script
      script | tee $output ) ;;
   *) quickchoice;;
   esac
done
}
#--------------------------------------------------------------------
# Add to / Print report, Add input to report, Clear report
#--------------------------------------------------------------------

add_input()
{
cat $input >> $report
}

add_output()
{
cat $output >> $report
}

change_printer()
{
echo "Printer: \c"; read PRINTER; export PRINTER
}

change_sqldir()
{
echo "\nSQL directory: [ $SQLDIR ] \c"; read answer
SQLDIR=${answer:-$SQLDIR}
echo "\n`pwd`\n"
ls $SQLDIR
}

clear_report()
{
rm -f $report
}

edit_input()
{
$EDITOR $input
}

edit_report()
{
$EDITOR $report
}

print_report()
{
cat $report | lp
}

print_output()
{
cat $output | lp
}

save_report()
{
echo "File: \c"; read file
mv $report $file
}

show_input()
{
$PAGER $input
}

show_output()
{
$PAGER $output
}

show_report()
{
$PAGER $report
}

rerun_input()
{
echo
echo $USER_PW | isql $ISQL_ARGS -w 2000 -i $input | sed '1d' | egrep -v 'return status' | tee $output
}

#--------------------------------------------------------------------
# The always available choices
#--------------------------------------------------------------------

quickchoice()
{
   case $answer in
   add_input) add_input;;
   add_output) add_output;;
   change_printer) change_printer;;
   change_sqldir) change_sqldir;;
   clear_report) clear_report;;
   db|database) set_database;;
   edit_input) edit_input;;
   edit_report) edit_report;;
   print_output) print_output;;
   print_report) print_report;;
   procs) sql='select name from sysobjects where type = "P"'; run_sql;;
   quit|exit) rm -f $input $output; exit;;
   rerun_input) rerun_input;;
   save_report) save_report;;
   server) set_server;;
   show_input) show_input;;
   show_output) show_output;;
   show_report) show_report;;
   tables) sql='select name from sysobjects where type = "U"'; run_sql;;
   help) help;;
   menu|\?) cat << EOB

   THESE MENU CHOICES ARE ALWAYS AVAILABLE

   help                 On-Line Help
   server               Change Server
   database             Change Database
   add_input            Add SQL input to report
   add_output           Add SQL output to report
   save_report          Save report in file
   edit_report          Edit report
   show_report          Show report
   print_output         Print output on default printer
   print_report         Print report on default printer
   change_printer       Change default printer
   change_sqldir        Change SQL Directory for own sql code
   clear_report         Clear report (start from scratch)
   show_output          Show output from SQL server again
   rerun_input          Rerun sql input to SQL server
   edit_input           Edit input to SQL server
   show_input           Show input to SQL server
   tables               Show all tables
   procs                Show all procedures
   exit                 Exit this script

EOB
   ;;
   *) echo "\n$answer is not a valid choice here\n";;
   esac
}

#--------------------------------------------------------------------
# Main menu
#--------------------------------------------------------------------

main ()
{
trap "stty echo; return" 1 2 15

while true; do
cat << EOB

   MAIN MENU

   ?    Show all other menu choices that always are active
   0    Quit
   1    Monitoring locks, blocks, processes
   2    Checking devices and allocations
   3    Checking user information
   4    List Objects
   5    Show help on Objects
   6    Reverse engineering
   7    Trouble Shooting
   8    Miscellaneous
   9    Running your own sql functions / scripts

   H    HELP

EOB
   echo "Choose: \c"
   read answer
   case "$answer" in
   0) rm -f $input $output; exit;;
   1) monitor;;
   2) space;;
   3) users;;
   4) list_objects;;
   5) info_on_objects;;
   6) regenerate;;
   7) trouble;;
   8) misc;;
   9) own;;
   H|h) help;;
   *) quickchoice;;
   esac
done
}

#--------------------------------------------------------------------
# Help
#--------------------------------------------------------------------

help()
{
cat << EOB

   H E L P - For the more sophisticated features.

   Choose ? to get the menu for tasks that are always available.

   You may wherever you are, type the name of a choice in the ? menu.
   E g you may type server to change server, type database to change database.

   If some command failed you may check the input (show_input)
   edit the input (edit_input) and rerun the input file (rerun_input).
   You may also check what was sent to isql (show_input).

   You may set a few environment variables before starting the script:

   \$SYBASE = the directory where bin/isql and interfaces should be located
   \${CONF_PREFIX}\$DSQUERY = A Bourne shell configuration file including at
                 least USER_PW=password. You must have one file per server.
                 You could set more things in the configuration files.
   \$DBDIR = Directory under where the reverse engineering should put
                 it's output.
   \$SQLDIR = Directory under where to put SQL code that the user may run.
   \$SCRIPTDIR = Directory under where to put scripts that the user may run.
   \$EDITOR = You may choose another editor than vi.
   \$PAGER = You may choose another pager than more.
   \$ISQL_ARGS = You may add some flags to the isql command.

   You may (change_sqldir) to where you got your reverse engineering code,
   and run them from within this tool. This is good since the reverse engineering
   won't add database or ending go. I have put this here since this is DANGEROUS
   if you do not know what you are doing.

   You may use this menu to create reports or advanced scripts. You do this
   by adding input (add_input) or output (add_output) to the report file
   and then edit (edit_report), save (save_report) and print the report file
   (print_report).

   You may always check which (tables) or (procs) you have in the current database.

   If the screen scrolled away and you do not have a screen with a scrollbar, you
   may reread the output by choosing (show_output).

EOB
   echo "Press return to continue"
   read stop
}

#--------------------------------------------------------------------
# Main loop
#--------------------------------------------------------------------

# Set default for customizable variables
# Put here to show what may be customized with environmet varibles

: ${SYBASE:=`csh -c "echo ~sybase"`}
: ${CONF_PREFIX:=$HOME/.}       # Config. file is $HOME/.$DSQUERY
: ${DBDIR:=$SYBASE/db}
: ${SCRIPTDIR:=$SYBASE/scripts}
: ${SQLDIR:=$SYBASE/sql}
: ${EDITOR:=vi}
: ${PAGER:=more}
: ${ISQL_ARGS:=""}

# Make sure echo uses SystemV syntax on all Sun hosts

PATH=/usr/5bin:/usr/bin:$PATH; export PATH

# Define all work files

input=/tmp/sybase_freebench.in.$$
output=/tmp/sybase_freebench.out.$$
report=sybase_freebench.rep.$$

# Protect the files

umask 077

# Make sure to exit properly

trap "stty echo; rm -f $input $output; exit" 1 2 15

# Give the user a wellcome sign

cat << EOB



        S Y B A S E   F R E E B E N C H


        This is a menu using Edward Barlow's extended procedures
        and Sybase own stored procedures
        built by Lars Karlsson, LM Ericsson Data AB, Sweden.

        It is free to use, with no support or warranty given,
        but you have to first install
        Edward Barlow's stored procedures into your SQL Servers.

		  These can be found on http://www.tiac.net/users/sqltech

        No functions in this script "should" be dangerous to run
        but as I said before, no warranty for this is given.

        ======================================

EOB

# Set server and run the menu

set_server
main

# Tell where the report is located if the user missed that

if [ -f "$report" ]; then
   echo "Your report is stored in $report"
fi
rm -f $input $output
