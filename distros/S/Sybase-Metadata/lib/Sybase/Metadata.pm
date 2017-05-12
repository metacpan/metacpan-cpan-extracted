package Sybase::Metadata;
use DBI;
use DBD::Sybase;
use strict;

# Module to perform get Sybase db and object info 
# Meant to be used in conjunction with CGI, etc to display info
# Contains subroutines to search through metadata by object
# type or globally - for present database
# Designed to be read-only for version 1.0

# Written by B. Michael O'Brien  8/2009

# History:

# Version 1 - 8/1/2009 Basic insight into metadata provided, 
#         basic search capabilities. More bells and whistles 
#         such as live data to be added later via another module.

# Note that this will be constructed as a class using bless so that
# we may refer to its instance variables downstream.

use Exporter;
our $VERSION = 1.00;
our @ISA = qw(Exporter);
our @EXPORT = qw($dbHandle
             &new
             &Initialize
             &GetDatabases
             &GetTables
             &GetProcs
             &GetViews
             &GetTriggers
             &GetRIs
             &GetIndexes
             &DescribeTable
             &DescribeProc
             &DescribeTrigger
             &DescribeView
             &GetUsers
             &GetLogins
             &GetGroups
             &ExtractTableSQL
             &ExtractViewSQL
             &ExtractProcSQL
             &ExtractTriggerSQL
             &ExtractRISQL
             &SearchProcNames
             &SearchProcText
             &SearchTriggerNames
             &SearchTriggerText
             &SearchColumns
             &SearchTables
             &SearchViewNames
             &SearchViewText
             &SearchIndexes
             &SearchUsers
             &SearchGroups
              );      

# Global variables

my $dbListSQL = '
select DBName      = d.name,
       DBID        = d.dbid,
       Owner       = l.name,
       CreateDate  = d.crdate
from  master.dbo.sysdatabases d, master.dbo.syslogins l
where d.suid = l.suid 
order by d.name';

my $getTablesSQL = '
select Name        = o.name,
       TableOID    = o.id,
       Owner       = u.name,
       CreateDate  = o.crdate
from sysobjects o, sysusers u
where o.type = "U"  and
      o.uid = u.uid
order by o.name';
       
my $getProcsSQL = '
select Name        = o.name,
       ProcOID     = o.id,
       Owner       = u.name,
       CreateDate  = o.crdate
from sysobjects o, sysusers u
where o.type = "P"  and
      o.uid = u.uid
order by o.name';

my $getViewsSQL = '
select Name        = o.name,
       ViewOID     = o.id,
       Owner       = u.name,
       CreateDate  = o.crdate
from sysobjects o, sysusers u
where o.type = "V"  and
      o.uid = u.uid
order by o.name';

my $getTriggersSQL = '
select TriggerName = o1.name,
       TriggerOID  = o1.id,
       TableName   = o2.name,
       TableOID    = o2.id
from sysobjects o1, sysobjects o2
where o1.type = "TR"        and
      (o1.deltrig = o2.id or
       o1.instrig = o2.id or
       o1.updtrig = o2.id)';

my $getRISQL = '
select Name          = o1.name, 
       RIOID         = o1.id,
       FromTable     = o2.name, 
       FromTableOID  = o2.id,
       ToTable       = o3.name,
       ToTableOID    = o3.id
from sysobjects o1, sysobjects o2, sysreferences r, sysobjects o3
where o1.type = "RI"      and
      o1.id = r.constrid  and
      o2.id = r.tableid   and
      r.reftabid = o3.id';

my $getIndexesSQL = '
select Name        = i.name,
       OnTable     = o.name,
       CreateDate  = i.crdate
from sysindexes i, sysobjects o
where i.id = o.id and o.type = "U"  and indid = 1';

my $describeTableSQL = '
select Name = c.name, 
       Type =  CASE
        when t.name in ("char","varchar","binary","varbinary") then t.name + "("+convert(varchar(9),c.length)+")"
        else t.name
       END,  -- case
       NullType = CASE
        when c.status = 0 then "NOT NULL"
        else "NULL"
       END -- case
from sysobjects o, syscolumns c, systypes t
where c.usertype = t.usertype  and
      c.id = o.id and
      o.name = ?
order by c.number';

my $getUsersSQL = '
select UserName    = u1.name, 
       UserID      = u1.uid,
	   GroupName   = u2.name,
       GroupID     = u1.gid     
from sysusers u1, sysusers u2
where  u1.gid *= u2.uid and
	  ((u1.uid < @@mingroupid and u1.uid != 0) 
				or (u1.uid > @@maxgroupid))';

my $getLoginsSQL = '
select LoginName   = name, 
       LoginID     = suid,
       DefaultDB   = dbname
from master.dbo.syslogins  ';

my $getGroupsSQL = '
select GroupName = name, 
       GroupID   = gid 
from sysusers u
where ((u.uid between @@mingroupid and @@maxgroupid) or u.uid = 0) 
	and not exists (select 1 from sysroles r where u.uid = r.lrid)';

my $GetMembersSQL = '
select UserName      = u2.name,
       UserID        = u2.uid
from sysusers u1, sysusers u2
where u1.name = ?  and
      u1.uid = u2.gid        and
      ((u2.uid < @@mingroupid and u2.uid != 0) or
       (u2.uid > @@maxgroupid))';

my $searchProcNamesSQL = '
select ProcName   = name,
       ProcOID    = id
from sysobjects 
where type = "P" and name like ?';

my $searchProcTextSQL = '
select ProcName = o.name,
       ProcOID  = o.id,
       Snippett = c.text
from sysobjects o, syscomments c
where o.id = c.id           and 
      o.type = "P"          and
      c.text like ?';

my $searchTrigNamesSQL = '
select TriggerName = o1.name,
       TriggerOID  = o1.id,
       TableName   = o2.name,
       TableOID    = o2.id
from sysobjects o1, sysobjects o2
where o1.name like ?  and
      o1.type = "TR"        and
      (o1.deltrig = o2.id or
       o1.instrig = o2.id or
       o1.updtrig = o2.id)';

my $searchTrigTextSQL = '
select TriggerName = o1.name,
       TriggerOID  = o1.id,
       TableName   = o2.name,
       TableOID    = o2.id,
       Snippett    = c.text
from sysobjects o1, sysobjects o2, syscomments c
where o1.type = "TR"        and
      o1.id = c.id          and
      c.text like ?  and
      (o1.deltrig = o2.id or
       o1.instrig = o2.id or
       o1.updtrig = o2.id)';

my $searchColumnsSQL = '
select ColumnName = c.name,
       TableName  = o.name,
       TableOID   = o.id
from sysobjects o, syscolumns c
where o.id = c.id  and
      o.type = "U" and
      c.name like ?';

my $searchTableNamesSQL = '
select TableName = name,
       TableOID  = id
from sysobjects 
where type = "U"  and
      name like ?';

my $searchViewNamesSQL = '
select ViewName = name,
       ViewOID  = id
from sysobjects 
where type = "V"  and
      name like ?';

my $searchViewTextSQL = '
select ViewName = o.name,
       ViewOID  = o.id,
       Snippett = c.text
from sysobjects o, syscomments c
where o.type = "V"  and
      o.id = c.id   and
      c.text like ?';

my $searchUsersSQL = '
select UserName  = name,
       UserID    = uid
from sysusers 
where name like ?  and
   (uid = 0 OR uid < @@mingroupid OR uid > @@maxgroupid)';

my $searchGroupsSQL = '
select GroupName = name,
       GroupID   = uid
from sysusers 
where name like ?  and
      uid between @@mingroupid and @@maxgroupid';

my $getTrigMetadataSQL = '
select constrid      = o1.id,
       FromTable     = o2.name, 
       ToTable       = o3.name
from sysobjects o1, sysobjects o2, sysreferences r, sysobjects o3
where o1.type = "RI"       and
      o1.id = r.constrid   and
      o2.id = r.tableid    and
      r.reftabid = o3.id   and 
      o1.name = ?'; 

my $getForKeysSQL = '
select FoKey = c.name
from  syscolumns c
where exists (select 1 from sysreferences r
              where constrid = ? and
                    r.tableid = c.id       and
                   (c.colid = r.fokey1  or
                    c.colid = r.fokey2  or
                    c.colid = r.fokey3  or
                    c.colid = r.fokey4  or
                    c.colid = r.fokey5  or
                    c.colid = r.fokey6  or
                    c.colid = r.fokey7  or
                    c.colid = r.fokey8  or
                    c.colid = r.fokey9  or
                    c.colid = r.fokey10 or
                    c.colid = r.fokey11 or
                    c.colid = r.fokey12 or
                    c.colid = r.fokey13 or
                    c.colid = r.fokey14 or
                    c.colid = r.fokey15 or
                    c.colid = r.fokey16)   )';

my $getRefKeysSQL = '
select RefKey = c.name
from  syscolumns c
where exists (select 1 from sysreferences r
              where constrid = ? and
                    r.tableid = c.id       and
                   (c.colid = r.refkey1  or
                    c.colid = r.refkey2  or
                    c.colid = r.refkey3  or
                    c.colid = r.refkey4  or
                    c.colid = r.refkey5  or
                    c.colid = r.refkey6  or
                    c.colid = r.refkey7  or
                    c.colid = r.refkey8  or
                    c.colid = r.refkey9  or
                    c.colid = r.refkey10 or
                    c.colid = r.refkey11 or
                    c.colid = r.refkey12 or
                    c.colid = r.refkey13 or
                    c.colid = r.refkey14 or
                    c.colid = r.refkey15 or
                    c.colid = r.refkey16)   )';

my $searchIndexesSQL = '
select IndexName        = i.name,
       TableName        = o.name,
       TableOID         = o.id
from sysindexes i, sysobjects o
where i.id = o.id   and 
      o.type = "U"  and 
      indid = 1     and 
      i.name like ?';


# Set DB Parameters (like initialization)

# Methods

####################################################################
#  
#  new
#   + Construct object and return handle
#
#   + Input:  None
#
#   + Output: Object handle/pointer
#
####################################################################
sub new {

  my       $self = {};
  bless    $self;

  return $self;

}

####################################################################
#  
#  Initialize
#   + Initialize desired db connection and return global handle
#
#    + Input:  Pointer to hash of DB properties containing:
#                 - Server
#                 - User
#                 - Password
#                 - Database
#
#    + Output: None but initializes db handle to be used internally
#
####################################################################

sub Initialize {

  # Initialize user parameters
  my $self = shift;
  my $dbPropsPtr = shift;
  $self->{DBNAME} = $dbPropsPtr->{DATABASE};
  $self->{SYBASE} = $ENV{SYBASE};
  $self->{SYBASE_OCS} = $ENV{SYBASE_OCS};
  $self->{USER}   = $dbPropsPtr->{USER};
  $self->{SERVER} = $dbPropsPtr->{SERVER};
  $self->{PASSWORD}  = $dbPropsPtr->{PASSWORD};
  $self->{DBHANDLE} = DBI->connect("dbi:Sybase:$self->{SERVER}","$self->{USER}","$self->{PASSWORD}");

  ($self->{DBHANDLE}->do("use $self->{DBNAME}") != -2)
        or warn "Cannot switch to $self->{DBNAME}\n";

  # Ensure Sybase environment variable is defined
  if (! $self->{SYBASE} =~ /\w/) {
    warn "You must define SYBASE environment variable\n";
    return undef;
  }

}


####################################################################
#  
#  GetDatabases
#   + Get a list of all databases and their space usage info
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#        DBName
#        DBID
#        Owner
#        CreateDate
#        
#
####################################################################

sub GetDatabases {

  my $self = shift;
  
  # Based on constant SQL $dbListSQL 
  my $sth = $self->{DBHANDLE}->prepare($dbListSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}


####################################################################
#  
#  GetTables
#   + Get a list of tables in present database, Useful for drill
#     down to table details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of table)
#               TableOID
#               Owner
#               CreateDate
#        
#
####################################################################

sub GetTables {

  my $self = shift;

  # Based on constant SQL $getTablesSQL
  my $sth = $self->{DBHANDLE}->prepare($getTablesSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}


####################################################################
#  
#  GetProcs
#   + Get a list of tables in present database, Useful for drill
#     down to table details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of proc)
#               ProcOID
#               Owner
#               CreateDate
#
####################################################################

sub GetProcs {

  my $self = shift;

  # Based on constant SQL $getProcsSQL
  my $sth = $self->{DBHANDLE}->prepare($getProcsSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}
 

####################################################################
#  
#  GetViews
#   + Get a list of views in present database, Useful for drill
#     down to view details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of view)
#               ViewOID
#               Owner
#               CreateDate
#
####################################################################

sub GetViews {

  my $self = shift;

  # Based on constant SQL $getViewsSQL
  my $sth = $self->{DBHANDLE}->prepare($getViewsSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}

 
####################################################################
#  
#  GetTriggers
#   + Get a list of views in present database, Useful for drill
#     down to view details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               TriggerName  
#               TriggerOID  
#               TableName   
#               TableOID 
#
####################################################################

sub GetTriggers {

  my $self = shift;

  # Based on constant SQL $getTriggersSQL
  my $sth = $self->{DBHANDLE}->prepare($getTriggersSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}         


####################################################################
#  
#  GetRIs
#   + Get a list of referential integrities in present database
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of referential inegtrity)
#               RIOID
#               FromTable
#               FromTableOID
#               ToTable
#               ToTableOID
#
####################################################################

sub GetRIs {

  my $self = shift;

  # Based on constant SQL $getRISQL
  my $sth = $self->{DBHANDLE}->prepare($getRISQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}   
     

####################################################################
#  
#  GetIndexes
#   + Get a list of indexes in present database
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of index)
#               OnTable
#               CreateDate
#
####################################################################

sub GetIndexes {

  my $self = shift;

  # Based on constant SQL $getIndexesSQL
  my $sth = $self->{DBHANDLE}->prepare($getIndexesSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

} 


 
####################################################################
#  
#  DescribeTable
#   + Get table details including column names, types, null/not null
#   + Input  : Table Name
#   + Output : Ref to array of hashes containing:
#               Name (of column)
#               Type
#               NullType (NULL/NOT NULL)
#
####################################################################

sub DescribeTable {

  my $self = shift;
  my $tableName = shift;

  # Based on constant SQL $describeTableSQL 
  my $sth = $self->{DBHANDLE}->prepare($describeTableSQL);

  $sth->execute($tableName);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  # Remove DEFNCOPY text
  my $junk = pop @resultsArray;


  return \@resultsArray;

}      
            
  
####################################################################
#  
#  DescribeProc
#   + Get stored proc text excluding create statements, etc
#   + Input  : Proc Name
#   + Output : Ref to array containing lines of text
#
####################################################################

sub DescribeProc {

  my $self = shift;
  my $procName = shift;
  my $tempFile = "$procName.$$";

  # Use defncopy to extract the info needed. Copy to a temporary file
  # and then put the results in an array by reading the file!
  my $defnCmd = "$self->{SYBASE}/$self->{SYBASE_OCS}/bin/defncopy -U $self->{USER} -S $self->{SERVER} -P $self->{PASSWORD} out $tempFile $self->{DBNAME} $procName";
 
  system($defnCmd);

  # open result file for processing
  open(FH,"<$tempFile") or  die "Could not open $tempFile - check directory permisisons\n";
  my @results = <FH>;

  close(FH);
  # Remove temporary file
  unlink($tempFile);

  # Remove DEFNCOPY text
  my $junk = pop @results;

  return \@results;

}              


####################################################################
#  
#  DescribeTrigger
#   + Get trigger text excluding create statements, etc
#   + Input  : Trigger Name
#   + Output : Ref to array containing lines of text
#
####################################################################

sub DescribeTrigger {

  my $self = shift;

  my $triggerName = shift;
  my $tempFile = "$triggerName.$$";

  # Use defncopy to extract the info needed. Copy to a temporary file
  # and then put the results in an array by reading the file!
  my $defnCmd = "$self->{SYBASE}/$self->{SYBASE_OCS}/bin/defncopy -U $self->{USER} -S $self->{SERVER} -P $self->{PASSWORD} out $tempFile $self->{DBNAME} $triggerName";
 
  system($defnCmd);

  # open result file for processing
  open(FH,"<$tempFile") or  die "Could not open $tempFile - check directory permisisons\n";
  my @results = <FH>;

  close(FH);
  # Remove temporary file
  unlink($tempFile);

   # Remove DEFNCOPY text
  my $junk = pop @results;

  return \@results;

}  
             
             
####################################################################
#  
#  DescribeView
#   + Get view text excluding create statements, etc
#   + Input  : ViewName
#   + Output : Ref to array containing lines of text
#
####################################################################

sub DescribeView {

  my $self = shift;

  my $viewName = shift;
  my $tempFile = "$viewName.$$";

  # Use defncopy to extract the info needed. Copy to a temporary file
  # and then put the results in an array by reading the file!
  my $defnCmd = "$self->{SYBASE}/$self->{SYBASE_OCS}/bin/defncopy -U $self->{USER} -S $self->{SERVER} -P $self->{PASSWORD} out $tempFile $self->{DBNAME} $viewName";
 
  system($defnCmd);

  # open result file for processing
  open(FH,"<$tempFile") or  die "Could not open $tempFile - check directory permisisons\n";
  my @results = <FH>;

  close(FH);
  # Remove temporary file
  unlink($tempFile);

  # Remove DEFNCOPY text
  my $junk = pop @results;


  return \@results;

}  
  
             

####################################################################
#  
#  GetUsers
#   + Get names/groups of all users in this database
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#                 UserName
#                 UserID
#                 GroupName
#                 GroupID
#   
#
####################################################################

sub GetUsers {

  my $self = shift;

  # Based on constant $getUsersSQL 
  my $sth = $self->{DBHANDLE}->prepare($getUsersSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}

             
####################################################################
#  
#  GetLogins
#   + Get names of all server level logins
#   + Input  : None
#   + Output : Ref to hash containing:
#                 LoginName
#                 LoginID
#                 DefaultDB
#
####################################################################

sub GetLogins {

  my $self = shift;

  # Based on constant $getLoginsSQL 
  my $sth = $self->{DBHANDLE}->prepare($getLoginsSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}
             

####################################################################
#  
#  GetGroups
#   + Get names of all groups in present database
#   + Input  : None
#   + Output : Ref to hash containing:
#                 GroupName
#                 GroupID
#
####################################################################

sub GetGroups {

  my $self = shift;

  # Based on constant $getGroupsSQL
  my $sth = $self->{DBHANDLE}->prepare($getGroupsSQL);

  $sth->execute();
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}

  
####################################################################
#  
#  GetGroupMembers
#   + Get list of all members of a given group
#   + Input  : GroupName
#   + Output : Ref to hash containing:
#               UserName
#               UserID
#
####################################################################

sub GetGroupMembers {

  my $self = shift;
  my $groupName = shift;

  # Based on constant $GetMembersSQL 
  my $sth = $self->{DBHANDLE}->prepare($GetMembersSQL);

  $sth->execute($groupName);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}           
 


####################################################################
#  
#  ExtractTableSQL
#   + Get entire stored proc with drop/create statements
#   + Input  : Table Name
#   + Output : Ref to array containing text
#
####################################################################

sub ExtractTableSQL {

  my $self = shift;
  my $tableName = shift;

  my $currSQL = "if not exists (select 1 from sysobjects where type = 'U' and name = '".$tableName."') \n";

  my @results = ($currSQL);
  push(@results,"BEGIN \n");
  $currSQL = "  CREATE TABLE ".$tableName."( \n";
  push(@results,$currSQL);
  my $columnsPtr = $self->DescribeTable($tableName);

  my $columnPtr;

  foreach $columnPtr (@{ $columnsPtr }) {
    my $currSQL = sprintf("%-30s %-20s %s,\n",$columnPtr->{Name},$columnPtr->{Type},$columnPtr->{NullType});
    push(@results,$currSQL);
  }

  push(@results,") \n");
  push(@results,"END\n");

  return \@results;

} 


####################################################################
#  
#  ExtractViewSQL
#   + Get entire view with drop/create statements
#   + Input  : View Name or View OID
#   + Output : Ref to array containing text
#
####################################################################

sub ExtractViewSQL {

  my $self = shift;
  my $viewName = shift;

  my $currSQL = "if not exists (select 1 from sysobjects where type = 'V' and name = '".$viewName."') \n";
  my @results = ($currSQL);
  push(@results,"BEGIN \n");
  my $viewDefPtr = $self->DescribeView($viewName);
  push(@results,@{ $viewDefPtr });
  push(@results,"END \n");

  return \@results;

}            
             
 
####################################################################
#  
#  ExtractProcSQL
#   + Get entire stored procedure with drop/create statements
#   + Input  : Proc Name or Proc OID
#   + Output : Ref to array containing text
#
####################################################################

sub ExtractProcSQL {

  my $self = shift;
  my $procName = shift;

  my $currSQL = "if not exists (select 1 from sysobjects where type = 'P' and name ='".$procName."') \n";
  my @results = ($currSQL);
  push(@results,"BEGIN \n");
  my $procDefPtr = $self->DescribeProc($procName);
  push(@results,@{ $procDefPtr });
  push(@results,"END \n");

  return \@results;

}                


####################################################################
#  
#  ExtractTriggerSQL
#   + Get entire trigger with drop/create statements
#   + Input  : Trigger Name or Trigger OID
#   + Output : Ref to array containing text
#
####################################################################

sub ExtractTriggerSQL {

  my $self = shift;
  my $triggerName = shift;

  my $currSQL = "if not exists (select 1 from sysobjects where type = 'TR' and name = '".$triggerName."') \n";
  my @results = ($currSQL);
  push(@results,"BEGIN \n");
  my $triggerDefPtr = $self->DescribeTrigger($triggerName);
  push(@results,@{ $triggerDefPtr });
  push(@results,"END \n");

  return \@results;

}
             
             
####################################################################
#  
#  ExtractRISQL
#   + Get entire referential integrity with drop/create statements
#   + Input  : RI Name
#   + Output : Ref to array containing text
#
####################################################################

sub ExtractRISQL {

  my $self = shift;
  my $RIName = shift;

  my $currSQL = "if not exists (select 1 from sysobjects \n";
  my @results = ($currSQL);
  $currSQL = "where type = 'RI' and name = '".$RIName."') \n";
  push(@results,$currSQL);
  push(@results,"begin \n");

  # Get table names, etc
  # $getTrigMetadataSQL 
  
  my $sth = $self->{DBHANDLE}->prepare($getTrigMetadataSQL);

  $sth->execute($RIName);
  my $resultsRef = $sth->fetchrow_hashref;

  # Ensure first item exists
#  if (undef $resultsRef->[0]) {
#    warn "RI ".$RIName." not found in db";
#    return undef;
#  }

  my ($constrid,
      $table,
      $reftable) =  
     ($resultsRef->{constrid},
      $resultsRef->{FromTable},
      $resultsRef->{ToTable});

  $currSQL = "alter table ".$table."\n";
  push(@results,$currSQL);
  $currSQL = "add constraint ".$RIName."\n";
  push(@results,$currSQL);
  $currSQL = "foreign key (";

  # Get foreign keys
  $sth = $self->{DBHANDLE}->prepare($getForKeysSQL);

  $sth->execute($constrid);
  $resultsRef = $sth->fetchall_arrayref({});

  foreach (@{ $resultsRef }) {
     $currSQL .= $_->{FoKey}.",";
  }

  # remove last comma 
  chop $currSQL;

  $currSQL .= ") \n";

  push(@results,$currSQL);

  $currSQL = "references ".$reftable." (";

  # Get ref keys
  $sth = $self->{DBHANDLE}->prepare($getRefKeysSQL);

  $sth->execute($constrid);
  $resultsRef = $sth->fetchall_arrayref({});
  my @resultsArray = @{ $resultsRef };
  my $hashPtr;

  foreach $hashPtr (@resultsArray) {
     $currSQL .= $hashPtr->{RefKey}.",";
  }

  # remove last comma 
  chop $currSQL;

  $currSQL .= ") \n";

  push(@results,$currSQL);

  push(@results,"end \n");

  return \@results;
  
}
             

####################################################################
#  
#  SearchProcNames
#   + Search proc names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ProcName
#               ProcOID
#
####################################################################

sub SearchProcNames {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchProcNamesSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchProcNamesSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}            

             
####################################################################
#  
#  SearchProcText
#   + Search proc text for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#    + Input  : Pattern (string with Sybase Reg Ex optional)
#    + Output : Ref To Array of hashes containing:
#               ProcName
#               ProcOID
#               Snippett (text within proc containing pattern)
#
####################################################################

sub SearchProcText {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchProcTextSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchProcTextSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}  
             

####################################################################
#  
#  SearchTriggerNames
#   + Search trigger names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               TriggerName
#               TriggerOID
#               TableName
#               TableOID
#
####################################################################

sub SearchTriggerNames {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchTrigNamesSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchTrigNamesSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}  


####################################################################
#  
#  SearchTriggerText
#   + Search trigger text for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               TriggerName
#               TriggerOID
#               TableName
#               TableOID
#               Snippett (piece of code containing pattern)
#
####################################################################

sub SearchTriggerText {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchTrigTextSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchTrigTextSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}


####################################################################
#  
#  SearchColumns
#   + Search column names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ColumnName
#               TableName
#               TableOID
#
####################################################################

sub SearchColumns {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchColumnsSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchColumnsSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}           
             

####################################################################
#  
#  SearchTableNames
#   + Search table names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               TableName
#               TableOID
#
####################################################################

sub SearchTableNames {

  my $self = shift; 
  my $pattern = shift;

  # Based on constant $searchTableNamesSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchTableNamesSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}
             

####################################################################
#  
#  SearchViewNames
#   + Search view names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ViewName
#               ViewOID
#
####################################################################

sub SearchViewNames {

  my $self = shift; 
  my $pattern = shift;

  # Based on constant $searchViewNamesSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchViewNamesSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}

             
####################################################################
#  
#  SearchViewText
#   + Search view names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ViewName
#               ViewOID
#               Snippett (bit of view containing pattern)
#
####################################################################

sub SearchViewText {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchViewTextSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchViewTextSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}
             

####################################################################
#  
#  SearchIndexNames
#   + Search index names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               IndexName
#               TableName
#               TableOID
#
####################################################################

sub SearchIndexNames {

  my $self = shift; 
  my $pattern = shift;

  # Based on constant $searchIndexesSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchIndexesSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}

 
####################################################################
#  
#  SearchUsers
#   + Search user names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               UserName
#               UserID
#
####################################################################

sub SearchUsers {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchUsersSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchUsersSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

}            

             
####################################################################
#  
#  SearchGroups
#   + Search group names for a given text pattern or sybase 
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               GroupName
#               GroupID
#
####################################################################

sub SearchGroups {

  my $self = shift;
  my $pattern = shift;

  # Based on constant $searchGroupsSQL 
  my $sth = $self->{DBHANDLE}->prepare($searchGroupsSQL);

  $sth->execute($pattern);
  my @resultsArray;
  my $rowRef;
  while ($rowRef = $sth->fetchrow_hashref())
  {
    push(@resultsArray,$rowRef);
  }

  return \@resultsArray;

} 
             

####################################################################
#  
#  CloseConnection
#   + Clean up and close DB handle
#   + Input: None needed
#
####################################################################

sub CloseConnection {

  my $self = shift;

  $self->{DBHANDLE}->disconnect;

} 




1;     #last line as required by perl modules
__END__

=head1 NAME

Sybase::Metadata 

=head1 SYNOPSIS

  use Sybase::Metadata;


=head1 DESCRIPTION

Sybase::Metadata provides methods to extract and search through Sybase metadata,
retrieving it for use in either general code or DB Browser applications.


=head2 EXPORT

 NB: You MUST have DBI and DBD:Sybase insatlled to use this module!

####################################################################
#
#  new
#   + Construct object and return handle
#
#   + Input:  None
#
#   + Output: Object handle/pointer
#
####################################################################
Example:

my $mdHandle = Sybase::Metadata->new();

####################################################################
# 
#  Initialize
#   + Initialize desired db connection and return global handle
#   NB: You MUST have DBI and DBD:Sybase insatlled to use this module!
#
#    + Input:  Pointer to hash of DB properties containing:
#                 - Server
#                 - User
#                 - Password
#                 - Database
#
#    + Output: None but initializes db handle to be used internally
#
####################################################################
Example:

my %dbHash = ( SERVER    => 'BIGDB_SERVER',
               USER      => 'SOME_USER',
               PASSWORD  => 'changeme',
               DATABASE  => 'BIGDB_DEV');

my $hashPtr = \%dbHash;

my $mdHandle = Sybase::Metadata->new();

$mdHandle->Initialize($hashPtr);


####################################################################
# 
#  GetDatabases
#   + Get a list of all databases and their space usage info
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#        DBName
#        DBID
#        Owner
#        CreateDate
# 
#
####################################################################
Example:

print "Testing GetDatabases ... \n";

my $dbListRef = $mdHandle->GetDatabases();

foreach ( @{$dbListRef}) {
  print "DBName = $_->{DBName}, DBID = $_->{DBID}, Owner = $_->{Owner}, CreateDate = $_->{CreateDate} \n";
}


####################################################################
# 
#  GetTables
#   + Get a list of tables in present database, Useful for drill
#     down to table details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of table)
#               TableOID
#               Owner
#               CreateDate
# 
#
####################################################################
Example:

print "\n Testing GetTables ... \n";

my $dbListRef = $mdHandle->GetTables();

foreach ( @{$dbListRef}) {
  print "Name = $_->{Name}, TableOID = $_->{TableOID}, Owner = $_->{Owner}, CreateDate = $_->{CreateDate} \n";
}


####################################################################
# 
#  GetProcs
#   + Get a list of tables in present database, Useful for drill
#     down to table details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of proc)
#               ProcOID
#               Owner
#               CreateDate
#
####################################################################
Example:

print "\n Testing GetProcs ... \n";

my $dbListRef = $mdHandle->GetProcs();

foreach ( @{$dbListRef}) {
  print "Name = $_->{Name}, ProcOID = $_->{ProcOID}, Owner = $_->{Owner}, CreateDate = $_->{CreateDate}  \n";
}


####################################################################
# 
#  GetViews
#   + Get a list of views in present database, Useful for drill
#     down to view details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of view)
#               ViewOID
#               Owner
#               CreateDate
#
####################################################################
Example:

print "\n Testing GetViews ... \n";

my $dbListRef = $mdHandle->GetViews();

foreach ( @{$dbListRef}) {
  print "Name = $_->{Name}, ViewOID = $_->{ViewOID}, Owner = $_->{Owner}, CreateDate = $_->{CreateDate} \n";
}


####################################################################
# 
#  GetTriggers
#   + Get a list of views in present database, Useful for drill
#     down to view details
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               TriggerName
#               TriggerOID
#               TableName
#               TableOID
#
####################################################################
Example:

print "\n Testing GetTriggers ... \n";

my $dbListRef = $mdHandle->GetTriggers();

foreach ( @{$dbListRef}) {
  print "TriggerName = $_->{TriggerName}, TriggerOID = $_->{TriggerOID}, TableName = $_->{TableName}, TableOID = $_->{TableOID} \n";
}


####################################################################
#
#  GetRIs
#   + Get a list of referential integrities in present database
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of referential inegtrity)
#               RIOID
#               FromTable
#               FromTableOID
#               ToTable
#               ToTableOID
#
####################################################################
Example:

print "\n Testing GetRIs ... \n";

my $dbListRef = $mdHandle->GetRIs();

foreach ( @{$dbListRef}) {
  print "Name = $_->{Name}, RIOID = $_->{RIOID}, FromTable = $_->{FromTable}, FromTableOID = $_->{FromTableOID}, ToTable = $_->{ToTable}, ToTableOID = $_->{ToTableOID}  \n";
}


####################################################################
#
#  GetIndexes
#   + Get a list of indexes in present database
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#               Name (name of index)
#               OnTable
#               CreateDate
#
####################################################################
Example:

print "\n Testing GetIndexes ... \n";

my $dbListRef = $mdHandle->GetIndexes();

foreach ( @{$dbListRef}) {
  print "Name = $_->{Name}, OnTable = $_->{OnTable}, CreateDate = $_->{CreateDate} \n";
}


####################################################################
# 
#  DescribeTable
#   + Get table details including column names, types, null/not null
#   + Input  : Table Name
#   + Output : Ref to array of hashes containing:
#               Name (of column)
#               Type
#               NullType (NULL/NOT NULL)
#
####################################################################
Example:

print "\n Testing DescribeTable ... \n";

my $dbListRef = $mdHandle->DescribeTable("MkEqTrade");

foreach ( @{$dbListRef}) {
  print "Name -> $_->{Name}, Type = $_->{Type}, NullType = $_->{NullType} \n";
}


####################################################################
# 
#  DescribeProc
#   + Get stored proc text excluding create statements, etc
#   + Input  : Proc Name
#   + Output : Ref to array containing lines of text
#
####################################################################
Example:

print "\n Testing DescribeProc ... \n";

my $dbListRef = $mdHandle->DescribeProc("MkGetEqProduct");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  DescribeTrigger
#   + Get trigger text excluding create statements, etc
#   + Input  : Trigger Name
#   + Output : Ref to array containing lines of text
#
####################################################################
Example:

print "\n Testing DescribeTrigger ... \n";

my $dbListRef = $mdHandle->DescribeTrigger("trigEqProdUpd");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  DescribeView
#   + Get view text excluding create statements, etc
#   + Input  : ViewName
#   + Output : Ref to array containing lines of text
#
####################################################################
Example:

print "\n Testing DescribeView ... \n";

my $dbListRef = $mdHandle->DescribeView("vEqHeaders");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  GetUsers
#   + Get names/groups of all users in this database
#   + Input  : None
#   + Output : Ref to array of hashes containing:
#                 UserName
#                 UserID
#                 GroupName
#                 GroupID
# 
#
####################################################################
Example:

print "\n Testing GetUsers ... \n";

my $dbListRef = $mdHandle->GetUsers();

foreach ( @{$dbListRef}) {
  print "UserName = $_->{UserName}, UserID = $_->{UserID}, GroupName = $_->{GroupName}, GroupID = $_->{GroupID} \n";
}


####################################################################
# 
#  GetLogins
#   + Get names of all server level logins
#   + Input  : None
#   + Output : Ref to hash containing:
#                 LoginName
#                 LoginID
#                 DefaultDB
#
####################################################################
Example:

print "\n Testing GetLogins ... \n";

my $dbListRef = $mdHandle->GetLogins();

foreach ( @{$dbListRef}) {
  print "LoginName = $_->{LoginName}, LoginID = $_->{LoginID}, DefaultDB = $_->{DefaultDB} \n";
}


####################################################################
# 
#  GetGroups
#   + Get names of all groups in present database
#   + Input  : None
#   + Output : Ref to hash containing:
#                 GroupName
#                 GroupID
#
####################################################################
Example:

print "\n Testing GetGroups ... \n";

my $dbListRef = $mdHandle->GetGroups();

foreach ( @{$dbListRef}) {
  print "GroupName = $_->{GroupName}, GroupID = $_->{GroupID} \n";
}


####################################################################
# 
#  GetGroupMembers
#   + Get list of all members of a given group
#   + Input  : GroupName
#   + Output : Ref to hash containing:
#               UserName
#               UserID
#
####################################################################
Example:

print "\n Testing GetGroupMembers ... \n";

my $dbListRef = $mdHandle->GetGroupMembers("app_group");

foreach ( @{$dbListRef}) {
  print "UserName = $_->{UserName}, UserID = $_->{UserID}  \n";
}


####################################################################
# 
#  ExtractTableSQL
#   + Get entire stored proc with drop/create statements
#   + Input  : Table Name
#   + Output : Ref to array containing text
#
####################################################################
Example:


print "\n Testing ExtractTableSQL ... \n";

my $dbListRef = $mdHandle->ExtractTableSQL("MkEqProductLog");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  ExtractViewSQL
#   + Get entire view with drop/create statements
#   + Input  : View Name or View OID
#   + Output : Ref to array containing text
#
####################################################################
Example:

print "\n Testing ExtractViewSQL ... \n";

my $dbListRef = $mdHandle->ExtractViewSQL("vEqHeaders");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  ExtractProcSQL
#   + Get entire stored procedure with drop/create statements
#   + Input  : Proc Name or Proc OID
#   + Output : Ref to array containing text
#
####################################################################
Example:

print "\n Testing ExtractProcSQL ... \n";

my $dbListRef = $mdHandle->ExtractProcSQL("MkGetEqProduct");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  ExtractTriggerSQL
#   + Get entire trigger with drop/create statements
#   + Input  : Trigger Name or Trigger OID
#   + Output : Ref to array containing text
#
####################################################################
Example:

print "\n Testing ExtractTriggerSQL ... \n";

my $dbListRef = $mdHandle->ExtractTriggerSQL("trigEqProdUpd");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  ExtractRISQL
#   + Get entire referential integrity with drop/create statements
#   + Input  : RI Name
#   + Output : Ref to array containing text
#
####################################################################
Example:


print "\n Testing ExtractRISQL ... \n";

my $dbListRef = $mdHandle->ExtractRISQL("FK_EQTRDATTR_TRDID");

foreach ( @{$dbListRef}) {
  print "$_ ";
}


####################################################################
# 
#  SearchProcNames
#   + Search proc names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ProcName
#               ProcOID
#
####################################################################
Example:

print "\n Testing SearchProcNames ... \n";

my $dbListRef = $mdHandle->SearchProcNames("%Get%");

foreach ( @{$dbListRef}) {
  print "ProcName = $_->{ProcName}, ProcOID = $_->{ProcOID}  \n";
}


####################################################################
# 
#  SearchProcText
#   + Search proc text for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#    + Input  : Pattern (string with Sybase Reg Ex optional)
#    + Output : Ref To Array of hashes containing:
#               ProcName
#               ProcOID
#               Snippett (text within proc containing pattern)
#
####################################################################
Example:

print "\n Testing SearchProcText ... \n";

my $dbListRef = $mdHandle->SearchProcText("%select%");

foreach ( @{$dbListRef}) {
  print "ProcName = $_->{ProcName}, ProcOID = $_->{ProcOID}, Snippett = $_->{Snippett}  \n";
}


####################################################################
# 
#  SearchTriggerNames
#   + Search trigger names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               TriggerName
#               TriggerOID
#               TableName
#               TableOID
#
####################################################################
Example:

print "\n Testing SearchTriggerNames ... \n";

my $dbListRef = $mdHandle->SearchTriggerNames("%[Uu]pd%");

foreach ( @{$dbListRef}) {
  print "TriggerName = $_->{TriggerName}, TriggerOID = $_->{TriggerOID}, TableName = $_->{TableName}, TableOID = $_->{TableOID}  \n";
}


####################################################################
# 
#  SearchTriggerText
#   + Search trigger text for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               TriggerName
#               TriggerOID
#               TableName
#               TableOID
#               Snippett (piece of code containing pattern)
#
####################################################################
Example:

print "\n Testing SearchTriggerText ... \n";

my $dbListRef = $mdHandle->SearchTriggerText("%ISIN%");

foreach ( @{$dbListRef}) {
  print "TriggerName = $_->{TriggerName}, TriggerOID = $_->{TriggerOID}, TableName = $_->{TableName}, TableOID = $_->{TableOID}, Snippett = $_->{Snippett}  \n";
}


####################################################################
# 
#  SearchColumns
#   + Search column names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ColumnName
#               TableName
#               TableOID
#
####################################################################
Example:

print "\n Testing SearchColumns ... \n";

my $dbListRef = $mdHandle->SearchColumns("%Product%");

foreach ( @{$dbListRef}) {
  print "ColumnName = $_->{ColumnName}, TableName = $_->{TableName}, TableOID = $_->{TableOID} \n";
}


####################################################################
# 
#  SearchTableNames
#   + Search table names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               TableName
#               TableOID
#
####################################################################
Example:

print "\n Testing SearchTableNames ... \n";

my $dbListRef = $mdHandle->SearchTableNames("%Product%");

foreach ( @{$dbListRef}) {
  print " TableName = $_->{TableName}, TableOID = $_->{TableOID} \n";
}


####################################################################
# 
#  SearchViewNames
#   + Search view names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ViewName
#               ViewOID
#
####################################################################
Example:

print "\n Testing SearchViewNames ... \n";

my $dbListRef = $mdHandle->SearchViewNames("%Eq%");

foreach ( @{$dbListRef}) {
  print " ViewName = $_->{ViewName}, ViewOID = $_->{ViewOID} \n";
}


####################################################################
# 
#  SearchViewText
#   + Search view names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               ViewName
#               ViewOID
#               Snippett (bit of view containing pattern)
#
####################################################################
Example:

print "\n Testing SearchViewText ... \n";

my $dbListRef = $mdHandle->SearchViewText("%[Ss]elect%");

foreach ( @{$dbListRef}) {
  print " ViewName = $_->{ViewName}, ViewOID = $_->{ViewOID}, Snippett = $_->{Snippett}  \n";
}


####################################################################
# 
#  SearchIndexNames
#   + Search index names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               IndexName
#               TableName
#               TableOID
#
####################################################################
Example:

print "\n Testing SearchIndexNames ... \n";

my $dbListRef = $mdHandle->SearchIndexNames("%EQ%");

foreach ( @{$dbListRef}) {
  print " IndexName = $_->{IndexName}, TableName = $_->{TableName}, TableOID = $_->{TableOID} \n";
}


####################################################################
# 
#  SearchUsers
#   + Search user names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               UserName
#               UserID
#
####################################################################
Example:

print "\n Testing SearchUsers ... \n";

my $dbListRef = $mdHandle->SearchUsers("%app%");

foreach ( @{$dbListRef}) {
  print " UserName = $_->{UserName}, UserID = $_->{UserID}  \n";
}


####################################################################
# 
#  SearchGroups
#   + Search group names for a given text pattern or sybase
#     regular expression. Will validate regular expression first.
#   + Input  : Pattern (string with Sybase Reg Ex optional)
#   + Output : Ref To Array of hashes containing:
#               GroupName
#               GroupID
#
####################################################################
Example:

print "\n Testing SearchGroups ... \n";

my $dbListRef = $mdHandle->SearchGroups("%app%");

foreach ( @{$dbListRef}) {
  print " GroupName = $_->{GroupName}, GroupID = $_->{GroupID}  \n";
}


####################################################################
#
#  CloseConnection
#   + Clean up and close DB handle
#   + Input: None needed
#
####################################################################
Example:

$mdHandle->CloseConnection();


=head1 SEE ALSO

For more information on this and other modules written by the author see
the website - http://www.bmobrien.net or email to mikeob723@gmail.com

=head1 AUTHOR

Mike O\'Brien, E<lt>mikeob723@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Mike O\'Brien

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

