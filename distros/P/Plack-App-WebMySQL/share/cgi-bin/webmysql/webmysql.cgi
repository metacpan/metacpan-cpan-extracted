#!/usr/bin/env perl
#web interface to a mysql server
#mt 21/09/2003 2.3	fixed bug when deleting the current database
#mt 28/09/2003 2.3	fixed ie logon by removing logon confirmation page
#mt 29/09/2003 2.3	fixed mysqldump import bug
#							wipe database now supported
#mt 16/11/2003 2.4	import file multiline single query bug fixed
#							empty table now supported
#mt 17/11/2003 2.4	fixed msdos import file bug
#mt 29/11/2003 2.5	Updated processfile sub to cope with ";" characters in sql commands
#mt 14/01/2004	2.6	Added mysqldump export support
#							improved processFile sub to do only one db connect, much faster now
#mt 16/03/2005	2.7	finished insert code
#							added explain to select queries
#							added table status info
use strict;
use warnings;
use CGI;
use DBI;
use DBD::mysql;
use lib "lib";
use Plack::App::WebMySQL;
use Plack::App::WebMySQL::Key;
use Plack::App::WebMySQL::General;
use Plack::App::WebMySQL::Sql;
use constant;	#for perl2exe
$error = undef;	#reset this every time, as PSGI will keep it for the lifetime of the server
$| = 1;	#disable output buffering, helps with CGIWrap
&expireKeys;	#remove old keys from server
if(&getData()){	#get the data from the last page's form
	if($form{'key'}){	#got a key do normal actions
		if(&readKey($form{'key'})){	#read the server side cookie for state
			$form{'menu'} = &parseFragmentToString("menu");	#load the top menu
			if($form{'action'} eq "mainmenu"){}	#just display a template
			elsif($form{'action'} eq "logout"){&deleteKey($form{'key'});}	#remove the server side cookie
			elsif($form{'action'} eq "query"){	#pick what type of query to run
				&updateKey($form{'key'});
			}
			elsif($form{'action'} eq "selectchoosetable"){	#pick what table to run the query type on
				$form{'tablelist'} = "";
				if(my @tables = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){
					for(my $tCount = 0; $tCount <= $#tables; $tCount++){$form{'tablelist'} .= "<tr><th><input type=\"checkbox\" name=\"table$tCount\" value=\"$tables[$tCount]\"></th><td>$tables[$tCount]</td></tr>\n";}	#convert to html format
					&updateKey($form{'key'});
				}
			}
			elsif($form{'action'} eq "selectchoosefields"){	#pick what fields to use in the query
				my @tablesTemp;
				foreach my $name (keys %form){
					if($name =~ m/^table\d+$/){push(@tablesTemp, $form{$name});}
				}
				if($#tablesTemp > -1){	#one or more tables have been selected
					$form{'tables'} = join(", ", @tablesTemp);	#for the server side cookie
					if(my @fields = &getFields($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'tables'})){
						$form{'fieldlist'} = "";
						for(my $count = 0; $count <= $#fields; $count++){$form{'fieldlist'} .= "<tr><th><input type=\"checkbox\" name=\"field" . ($count + 1) . "\" value=\"$fields[$count]\"></th><td>$fields[$count]</td></tr>\n";}	#convert to html format
						&updateKey($form{'key'});
					}
				}
				else{$error = "You did not select any tables to query";}
			}
			elsif($form{'action'} eq "selectchoosecriteria"){	#pick the criteria for the query
				my @tmpFields;
				foreach my $name (keys %form){
					if($name =~ m/^field\d+$/){push(@tmpFields, $form{$name});}
				}
				$form{'fields'} = join(", ", @tmpFields);	#for the server side cookie
				if(my @fields = &getFields($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'tables'})){
					if($form{'tables'} =~ m/, /){	#more than one table selected, show the join options
						my @tables = split(/, /, $form{'tables'});
						$form{'joinlist'} = "<p>Please select how you want to join the tables to $tables[0]</p>\n";
						$form{'joinlist'} .= "<table border=\"1\" align=\"center\" bgcolor=\"#8899DD\">\n";
						for(my $tCount = 1; $tCount <= $#tables; $tCount++){
							$form{'joinlist'} .= "<tr>\n";
							$form{'joinlist'} .= "<td>left join $tables[$tCount] on</td>\n";
							$form{'joinlist'} .= "<td>\n";
							$form{'joinlist'} .= "<select name=\"joinfield1_$tables[$tCount]\">\n";
							foreach(@fields){
								if($_ !~ m/\*$/){	#ignore these fields
									$form{'joinlist'} .= "<option value=\"$_\">$_</option>";
								}
							}
							$form{'joinlist'} .= "</select>\n";
							$form{'joinlist'} .= "</td>\n";
							$form{'joinlist'} .= "<td>=</td>\n";
							$form{'joinlist'} .= "<td>\n";
							$form{'joinlist'} .= "<select name=\"joinfield2_$tables[$tCount]\">\n";
							foreach(@fields){
								if($_ !~ m/\*$/){	#ignore these fields
									$form{'joinlist'} .= "<option value=\"$_\">$_</option>";
								}
							}
							$form{'joinlist'} .= "</select>\n";
							$form{'joinlist'} .= "</td>\n";
							$form{'joinlist'} .= "</tr>\n";
						}
						$form{'joinlist'} .= "</table>\n";
					}
					else{$form{'joinlist'} = "";}	#join not used for just one table
					$form{'criterialist'} = "";
					for(my $count = 0; $count <= 5; $count++){
						$form{'criterialist'} .= "<tr>";
						$form{'criterialist'} .= "<td><select name=\"critname$count\"><option value=\"\"></option>";
						foreach(@fields){
							if($_ !~ m/\*$/){	#ignore these fields
								$form{'criterialist'} .= "<option value=\"$_\">$_</option>";
							}
						}
						$form{'criterialist'} .= "</select></td>";
						$form{'criterialist'} .= "<td><select name=\"crithow$count\">";
						foreach("=", ">=", "<=", ">", "<", "!=", "LIKE", "REGEXP"){$form{'criterialist'} .= "<option value=\"$_\">$_</option>";}
						$form{'criterialist'} .= "</select></td>";
						$form{'criterialist'} .= "<td><input type=\"text\" name=\"crit$count\"></td>";
						if($count < 5){$form{'criterialist'} .= "<td><select name=\"critappend$count\"><option value=\"AND\">AND</option><option value=\"OR\">OR</option></select></td>";}
						else{$form{'criterialist'} .= "<td>&nbsp;</td>";}
						$form{'criterialist'} .= "</tr>\n";
					}
					$form{'orderbylist'} = "";
					foreach(@fields){
						if($_ !~ m/\*$/){	#ignore these fields
							$form{'orderbylist'} .= "<option value=\"$_\">$_</option>\n";
						}
					}
					&updateKey($form{'key'});
				}
			}
			elsif($form{'action'} eq "runquery"){	#run the query
				$form{'sql'} = &composeSelect();
				$form{'explainrecords'} = &explainQuery($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'sql'});
				$form{'queryrecords'} = &runQuery($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'sql'});
			}
			elsif($form{'action'} eq "managetables"){	#show table list
				$form{'tablelist'} = "";
				if(my @tables = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){
					foreach(@tables){	#convert to html format
						$form{'tablelist'} .= "<tr>\n";
						$form{'tablelist'} .= "<td>$_</td>\n";
						$form{'tablelist'} .= "<th>\n";
						$form{'tablelist'} .= "<form action=\"$ENV{'SCRIPT_NAME'}\" method=\"POST\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"key\" value=\"$form{'key'}\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"tables\" value=\"$_\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"action\" value=\"describe\">\n";
						$form{'tablelist'} .= "<input type=\"submit\" value=\"Info\">\n";
						$form{'tablelist'} .= "</form>\n";
						$form{'tablelist'} .= "</th>\n";
						$form{'tablelist'} .= "<th>\n";
						$form{'tablelist'} .= "<form action=\"$ENV{'SCRIPT_NAME'}\" method=\"POST\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"key\" value=\"$form{'key'}\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"tables\" value=\"$_\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"action\" value=\"emptytable\">\n";
						$form{'tablelist'} .= "<input type=\"submit\" value=\"Empty\">\n";
						$form{'tablelist'} .= "</form>\n";
						$form{'tablelist'} .= "</th>\n";
						$form{'tablelist'} .= "<th>\n";
						$form{'tablelist'} .= "<form action=\"$ENV{'SCRIPT_NAME'}\" method=\"POST\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"key\" value=\"$form{'key'}\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"tables\" value=\"$_\">\n";
						$form{'tablelist'} .= "<input type=\"hidden\" name=\"action\" value=\"droptable\">\n";
						$form{'tablelist'} .= "<input type=\"submit\" value=\"Drop\">\n";
						$form{'tablelist'} .= "</form>\n";
						$form{'tablelist'} .= "</th>\n";
						$form{'tablelist'} .= "</tr>\n";
					}
					delete $form{'tables'};
					&updateKey($form{'key'});
				}
			}
			elsif($form{'action'} eq "describe"){	#display table list
				if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
					$form{'queryrecords'} = &runQuery($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "DESCRIBE $1;");
					$form{'statusrecords'} = &runQueryVert($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "SHOW TABLE STATUS LIKE '$1';");
				}
				else{$error = "Table name contains invalid characters";}
			}
			elsif($form{'action'} eq "serverinfo"){	#shows processlist
				$form{'queryrecords'} = &runQuery($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "SHOW PROCESSLIST;");
			}
			elsif($form{'action'} eq "droptable"){
				if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
					$form{'rows'} = &getTableRows($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'tables'});
					&updateKey($form{'key'});
				}
				else{$error = "Table name contains invalid characters";}
			}
			elsif($form{'action'} eq "droptableconfirm"){
				if($form{'answer'} eq "yes"){	#user confirmed drop
					if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
						$form{'queryrecords'} = &runNonSelect($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "DROP TABLE $1;");
					}
					else{$error = "Table name contains invalid characters";}
				}
				else{$error = "You did not confirm that you wanted the table dropped";}
			}
			elsif($form{'action'} eq "emptytable"){
				if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
					$form{'rows'} = &getTableRows($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'tables'});
					&updateKey($form{'key'});
				}
				else{$error = "Table name contains invalid characters";}
			}
			elsif($form{'action'} eq "emptytableconfirm"){
				if($form{'answer'} eq "yes"){	#user confirmed drop
					if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
						$form{'queryrecords'} = &runNonSelect($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "DELETE FROM $1;");
					}
					else{$error = "Table name contains invalid characters";}
				}
				else{$error = "You did not confirm that you wanted the table dropped";}
			}
			elsif($form{'action'} eq "createtable"){	#chose a new table name
				delete $form{'tables'};
				&updateKey($form{'key'});
			}
			elsif($form{'action'} eq "createtablefields"){	#show table creation page
				if($form{'tables'} ne ""){
					if(length($form{'tables'}) <= 64){
						if($form{'tables'} =~ m/^\w+$/){
							my @tables = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'});
							if($#tables > -1){	# the current database already has some tables in it
								my $exists = 0;
								foreach(@tables){
									if($_ eq $form{'tables'}){	#found this table name already
										$exists = 1;
										last;
									}
								}
								if(!$exists){	#this name name does not exist already
									$form{'currentfields'} = &getCreationFields();
									$form{'removefields'} = "";
									if($form{'creationfnames'}){
										my @fields = split(/�/, $form{'creationfnames'});
										foreach(@fields){$form{'removefields'} .= "<option value=\"$_\">$_</option>\n";}
									}
									&updateKey($form{'key'});
								}
								else{$error = "The table name you specified already exists in the current database";}
							}
							elsif(!$error){	#no current tables in database
								delete $form{'creationfnames'};
								delete $form{'creationftypes'};
								delete $form{'creationfsizes'};
								delete $form{'creationfnull'};
								$form{'currentfields'} = "";
								$form{'removefields'} = "";
								&updateKey($form{'key'});
							}
						}
						else{$error = "The table name you specified contains invalid characters";}
					}
					else{$error = "The table name you specified is too long";}
				}
				else{$error = "You did not enter a name for the new table";}
			}
			elsif($form{'action'} eq "createtableaddfield"){	#add a new field to the table
				if($form{'fname'} ne ""){	#the user has typed a field name in
					if($form{'fsize'} eq ""){$form{'fsize'} = 0;}
					my $found = 0;
					if($form{'creationfnames'}){	#we have some fields already
						foreach(split(/�/, $form{'creationfnames'})){	#search the current list of field names to be
							if($_ eq $form{'fname'}){
								$found = 1;
								last;
							}
						}
					}
					if(!$found){
						if(defined($form{'fnull'}) && $form{'fnull'} eq "on"){$form{'fnull'} = "Y";}
						else{$form{'fnull'} = "N";}
						if(!exists($form{'creationfnames'})){
							$form{'creationfnames'} = $form{'fname'};
							$form{'creationftypes'} = $form{'ftype'};
							$form{'creationfsizes'} = $form{'fsize'};
							$form{'creationfnulls'} = $form{'fnull'};
						}
						else{
							$form{'creationfnames'} .= "�$form{'fname'}";
							$form{'creationftypes'} .= "�$form{'ftype'}";
							$form{'creationfsizes'} .= "�$form{'fsize'}";
							$form{'creationfnulls'} .= "�$form{'fnull'}";
						}	#append
						&updateKey($form{'key'});
						$form{'currentfields'} = &getCreationFields();
						my @fields = split(/�/, $form{'creationfnames'});
						$form{'removefields'} = "";
						foreach(@fields){$form{'removefields'} .= "<option value=\"$_\">$_</option>\n";}
						$form{'action'} = "createtablefields";	#send user back to the table creation page
					}
					else{$error = "A field with the name specified already exists in this table";}
				}
				else{$error = "You did not specify a field name";}
			}
			elsif($form{'action'} eq "createtablenow"){	#create the table now
				if($form{'creationfnames'}){
					my $sql = "CREATE TABLE $form{'tables'} (";
					my @names = split(/�/, $form{'creationfnames'});
					my @types = split(/�/, $form{'creationftypes'});
					my @sizes = split(/�/, $form{'creationfsizes'});
					my @nulls = split(/�/, $form{'creationfnulls'});
					for(my $count = 0; $count <= $#names; $count++){
						$sql .= "$names[$count] $types[$count]";
						if($sizes[$count] != 0){$sql .= "($sizes[$count])";}	#include size for this field
						if($nulls[$count] eq "N"){$sql .= " NOT NULL";}	#this field is not null
						if($count < $#names){$sql .= ", ";}
					}
					$sql .= ");";
					#print STDERR "$sql\n";
					$form{'queryrecords'} = &runNonSelect($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $sql);
				}
				else{$error = "This table has no fields yet";}
			}
			elsif($form{'action'} eq "createtableremovefield"){
				if($form{'fname'} ne ""){
					my @names = split(/�/, $form{'creationfnames'});
					my @types = split(/�/, $form{'creationftypes'});
					my @sizes = split(/�/, $form{'creationfsizes'});
					my @nulls = split(/�/, $form{'creationfnulls'});
					$form{'creationfnames'} = "";
					$form{'creationftypes'} = "";
					$form{'creationfsizes'} = "";
					for(my $count = 0; $count <= $#names; $count++){
						if($names[$count] ne $form{'fname'}){
							if($form{'creationfnames'} eq ""){
								$form{'creationfnames'} .= $names[$count];
								$form{'creationftypes'} .= $types[$count];
								$form{'creationfsizes'} .= $sizes[$count];
								$form{'creationfnulls'} .= $nulls[$count];
							}
							else{
								$form{'creationfnames'} .= "�$names[$count]";
								$form{'creationftypes'} .= "�$types[$count]";
								$form{'creationfsizes'} .= "�$sizes[$count]";
								$form{'creationfnulls'} .= "�$nulls[$count]";
							}
						}
					}
					if($form{'creationfnames'} eq ""){	#remove empty hash elements
						delete $form{'creationfnames'};
						delete $form{'creationftypes'};
						delete $form{'creationfsizes'};
						delete $form{'creationfnulls'};
					}
					&updateKey($form{'key'});
					$form{'currentfields'} = &getCreationFields();
					$form{'removefields'} = "";
					if($form{'creationfnames'}){	#if we have some fields already
						@names = split(/�/, $form{'creationfnames'});	#get the new list of names
						foreach(@names){$form{'removefields'} .= "<option value=\"$_\">$_</option>\n";}
					}
					$form{'action'} = "createtablefields";	#send user back to the table creation page
				}
				else{$error = "You did not specify a field name to remove";}
			}
			elsif($form{'action'} eq "managedatabases"){
				if(my @dbs = &getDatabases($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){
					$form{'databaselist'} = "";
					foreach(@dbs){	#convert to html format
						$form{'databaselist'} .= "<tr>\n";
						$form{'databaselist'} .= "<td>$_</td>\n";
						$form{'databaselist'} .= "<th>";
						$form{'databaselist'} .= "<form action=\"$ENV{'SCRIPT_NAME'}\" method=\"POST\">";
						$form{'databaselist'} .= "<input type=\"hidden\" name=\"key\" value=\"$form{'key'}\">";
						$form{'databaselist'} .= "<input type=\"hidden\" name=\"db\" value=\"$_\">";
						$form{'databaselist'} .= "<input type=\"hidden\" name=\"action\" value=\"usedatabase\">";
						$form{'databaselist'} .= "<input type=\"submit\" value=\"Use\">";
						$form{'databaselist'} .= "</form>";
						$form{'databaselist'} .= "</th>\n";
						if($_ eq "mysql"){$form{'databaselist'} .= "<th>&nbsp;</th><th>&nbsp;</th>\n";}	#cant delete this table
						else{
							$form{'databaselist'} .= "<th>";
							$form{'databaselist'} .= "<form action=\"$ENV{'SCRIPT_NAME'}\" method=\"POST\">";
							$form{'databaselist'} .= "<input type=\"hidden\" name=\"key\" value=\"$form{'key'}\">";
							$form{'databaselist'} .= "<input type=\"hidden\" name=\"db\" value=\"$_\">";
							$form{'databaselist'} .= "<input type=\"hidden\" name=\"action\" value=\"dropdatabase\">";
							$form{'databaselist'} .= "<input type=\"submit\" value=\"Drop\">";
							$form{'databaselist'} .= "</form>";
							$form{'databaselist'} .= "</th>";
							$form{'databaselist'} .= "<th>";
							$form{'databaselist'} .= "<form action=\"$ENV{'SCRIPT_NAME'}\" method=\"POST\">";
							$form{'databaselist'} .= "<input type=\"hidden\" name=\"key\" value=\"$form{'key'}\">";
							$form{'databaselist'} .= "<input type=\"hidden\" name=\"db\" value=\"$_\">";
							$form{'databaselist'} .= "<input type=\"hidden\" name=\"action\" value=\"wipedatabase\">";
							$form{'databaselist'} .= "<input type=\"submit\" value=\"Empty\">";
							$form{'databaselist'} .= "</form>";
							$form{'databaselist'} .= "</th>\n";
						}
						$form{'databaselist'} .= "</tr>\n";
					}
					delete $form{'db'};
					&updateKey($form{'key'});
				}
			}
			elsif($form{'action'} eq "dropdatabase"){
				if($form{'db'} =~ m/^(\w+)$/){	#safety check on table name
					$form{'numtables'} = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'db'});
					&updateKey($form{'key'});
				}
				else{$error = "Database name contains invalid characters";}
			}
			elsif($form{'action'} eq "dropdatabaseconfirm"){
				if($form{'answer'} eq "yes"){	#user confirmed drop
					if($form{'db'} =~ m/^(\w+)$/){	#safety check on table name
						$form{'queryrecords'} = &runNonSelect($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "DROP DATABASE $1;");
						if($form{'queryrecords'}){	#drop database worked
							if($form{'db'} eq $form{'database'}){	#dropped the current database
								delete $form{'database'};	#stop using the now deleted database
								&updateKey($form{'key'});	#update the session								
							}
						}
					}
					else{$error = "Database name contains invalid characters";}
				}
				else{$error = "You did not confirm that you wanted the database dropped";}
			}
			elsif($form{'action'} eq "wipedatabase"){
				if($form{'db'} =~ m/^(\w+)$/){	#safety check on table name
					$form{'numtables'} = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'db'});
					&updateKey($form{'key'});
				}
				else{$error = "Database name contains invalid characters";}
			}
			elsif($form{'action'} eq "wipedatabaseconfirm"){
				if($form{'answer'} eq "yes"){	#user confirmed drop
					if($form{'db'} =~ m/^(\w+)$/){	#safety check on table name
						my @tables = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'db'});	#find the tables for this database
						foreach(@tables){	#delete every table
							my $result = &runNonSelect($form{'host'}, $form{'user'}, $form{'password'}, $form{'db'}, "DROP TABLE $_;");
							if(!$result){last;}	#if we get an error stop now
						}
					}
					else{$error = "Database name contains invalid characters";}
				}
				else{$error = "You did not confirm that you wanted the database dropped";}
			}
			elsif($form{'action'} eq "createdatabase"){	#chose a new database name
				delete $form{'db'};
				&updateKey($form{'key'});
			}
			elsif($form{'action'} eq "createdatabasenow"){
				if($form{'db'} ne ""){
					if(length($form{'db'}) <= 64){
						if($form{'db'} =~ m/^\w+$/){
							if(my @dbs = &getDatabases($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){
								my $exists = 0;
								foreach(@dbs){
									if($_ eq $form{'db'}){	#found this database name already
										$exists = 1;
										last;
									}
								}
								if(!$exists){	#this name name does not exist already
									&runNonSelect($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "CREATE DATABASE $form{'db'};");
								}
								else{$error = "The database name you specified already exists";}
							}
						}
						else{$error = "The database name you specified contains invalid characters";}
					}
					else{$error = "The database name you specified is too long";}
				}
				else{$error = "You did not enter a name for the new database";}
			}
			elsif($form{'action'} eq "usedatabase"){
				if($form{'db'} ne ""){
					if(length($form{'db'}) <= 64){
						if($form{'db'} =~ m/^\w+$/){
							if(my @dbs = &getDatabases($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){
								my $exists = 0;
								foreach(@dbs){
									if($_ eq $form{'db'}){	#found this database name already
										$exists = 1;
										last;
									}
								}
								if($exists){	#this name name does not exist already
									$form{'database'} = $form{'db'};	#save the new database
									delete $form{'db'};
									&updateKey($form{'key'});
								}
								else{$error = "The database name you specified already exists";}
							}
						}
						else{$error = "The database name you specified contains invalid characters";}
					}
					else{$error = "The database name you specified is too long";}
				}
				else{$error = "You did not enter a name for the new database";}
			}
			elsif($form{'action'} eq "importdumpform"){}	#just display template
			elsif($form{'action'} eq "importdump"){
				my @parts = split(/\\/, $form{'dumpfile'});	#ms browser fix
				my $file = $parts[$#parts];
				if($file){
					if($file =~ m/^(\w|\.|\-|\_)+$/){	#make sure filename is not silly
						if(&uploadFile($file)){
							$form{'commands'} = &processFile($file);	#execute the sql statements and count them
							unlink("dump_uploads/$file");
						}
					}
					else{$error = "Dumpfile name contains invalid characters";}
				}
				else{$error = "You did not select a dumpfile to import";}
			}
			elsif($form{'action'} eq "insertchoosetable"){	#pick what table to run the query type on
				$form{'tablelist'} = "";
				if(my @tables = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){
					for(my $tCount = 0; $tCount <= $#tables; $tCount++){$form{'tablelist'} .= "<option value=\"$tables[$tCount]\">$tables[$tCount]</option>\n";}	#convert to html format
					delete($form{'tables'});	#wipe this before the user makes a talbe choice
					foreach my $key (keys %form){	#delete any pending insert records from a unfinished insert
						if($key =~ m/^insertdata\d+$/){delete $form{$key};}
					}
					&updateKey($form{'key'});
				}
			}
			elsif($form{'action'} eq "insertform"){	#display insert form
				if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
					my $table = $1;
					if(my @fields = &getFieldsShort($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'tables'})){
						$form{'input'} = &createInsertForm($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $table);
						$form{'fields'} = "";
						foreach(@fields){$form{'fields'} .= "<th>$_</th>";}	#create the field name headings
						&updateKey($form{'key'});
					}
				}	
				else{$error = "Table name contains invalid characters";}
			}
			elsif($form{'action'} eq "insert"){	#add the record to the list of pending records
				if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
					my $table = $1;
					if(my @fields = &getFieldsShort($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'tables'})){
						my $sql = "INSERT INTO $table (";	#starting sql
						$sql .= join(",", @fields) . ") VALUES(";	#add the table fields	
						my $dbh = DBI -> connect("DBI:mysql:database=$form{'database'};host=$form{'host'}", $form{'user'}, $form{'password'});
						if($dbh){
							for(my $i = 0; $i <= $#fields; $i++){
								if($form{"insert_" . $i} eq ""){$sql .= "'',";}	#now value entered
								else{$sql .= $dbh -> quote($form{"insert_" . $i}) . ",";}
							}
							$dbh -> disconnect();
						}
						else{$error = "Cant connect to MySQL server: " . $DBI::errstr;}
						$sql = substr($sql, 0, (length($sql) - 1));	#get rid of the last comma
						$sql .= ");";	#ending sql
						$form{'affected'} = &runNonSelect($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $sql);	#insert the data
						$form{'code'} = &displaySQL($sql);
						$form{'action'} = "insertcomplete";	#got back to the same page we came from
					}
				}
			}
			elsif($form{'action'} eq "exportdump"){	#send the dump file to the browser
				&createDumpFile();	#make the export file
				if(!$error){	#display an error message instead of the dump file
					if(open(EXPORT, "<dump_downloads/$form{'key'}.sql")){	#able to read the export file
						print "Content type: application/oct-stream\n\n";	#tell the browser it's a binary file
						while(<EXPORT>){print;}	#send the whole file to the browser
						close(EXPORT);
					}
					else{$error = "Unable to read export file: $!";}
				}
				unlink("dump_downloads/$form{'key'}.sql");	#remove temp file
			}
			else{$error = "Invalid action: $form{'action'}";}	#a strange action has been found
		}
		else{$form{'action'} = "login";}	#send to the starting page if no key has been given, or not logging in
	}
	else{	#must be a starting page or a login
		if($form{'action'} && $form{'action'} eq "connect"){	#a login
			if(&testConnect($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){	#mysql login detail are correct
				$form{'key'} = &createKey();	#created new server side cookie file
				&updateKey($form{'key'});
				$form{'action'} = "mainmenu";	#display the main menu
				$form{'menu'} = &parseFragmentToString("menu");	#load the top menu
			}
		}
		else{$form{'action'} = "login";}	#display the starting page
	}
}
if($form{'action'} ne "exportdump" || $error){	#only show a html template if we are not outputting text etc.
	print "Content-type: text/html\n\n";
	&parsePage("header", 1);
	&parsePage($form{'action'}, 0);
	&parsePage("footer", 1);
}
exit(0);
##################################################################################################################
sub composeSelect{	#generates the sql code for a select query
	my $code = "SELECT ";
	if($form{'distinct'}){$code .= "DISTINCT ";}	#distinct results only
	$code .= "$form{'fields'}";	#add the fields to show
	if($form{'groupby'} ne "" && $form{'groupfunc'} ne "" && $form{'funcfield'} ne ""){	#user is grouping with a group function
		$code .= ", $form{'groupfunc'}($form{'funcfield'})";
	}
	$code .= " FROM ";
	my @tables = split(/, /, $form{'tables'});
	$code .= $tables[0];
	if($form{'tables'} =~ m/, /){
		for(my $tCount = 1; $tCount <= $#tables; $tCount++){
			$code .= " LEFT JOIN $tables[$tCount] ON $form{'joinfield1_' . $tables[$tCount]} = $form{'joinfield2_' . $tables[$tCount]}";
		}
	}
	my $criteria = "";
	my $count = 0;
	while($form{'critname' . $count} ne ""){
		$criteria .= $form{'critname' . $count} . " " . $form{'crithow' . $count} . " '" . $form{'crit' . $count} . "'";
		if(exists($form{'critname' . ($count + 1)}) && $form{'critname' . ($count + 1)}){$criteria .= " " . $form{'critappend' . $count} . " ";}
		$count++;
	}
	if($criteria ne ""){$code .= " WHERE $criteria";}
	if($form{'groupby'} ne ""){$code .= " GROUP BY $form{'groupby'}";}	#add grouping
	if($form{'orderby'} ne ""){
		$code .= " ORDER BY $form{'orderby'}";	#add sorting
		if($form{'desc'}){$code .= " DESC";}	#reverse sorting
	}
	$code .= ";";
	return $code;
}
##############################################################################################################
sub getCreationFields{
	my $html = "";
	if(exists($form{'creationfnames'})){	#user has chosen some fields already
		my @names = split(/�/, $form{'creationfnames'});
		my @types = split(/�/, $form{'creationftypes'});
		my @sizes = split(/�/, $form{'creationfsizes'});
		my @nulls = split(/�/, $form{'creationfnulls'});
		for(my $count = 0; $count <= $#names; $count++){
			$html .= "<tr><td>$names[$count]</td><td>$types[$count]";
			if($sizes[$count] > 0){$html .= "($sizes[$count])";}	#print the size
			$html .= "</td>";
			if($nulls[$count] eq "Y"){$html .= "<td>YES</td>";}	#show that this field is null
			else{$html .= "<td></td>";}
			$html .= "<td></td><td></td><td></td></tr>\n";
		}
	}
	return $html;
}
############################################################################################################################
sub uploadFile{
	my $file = shift;
	my $result = 0;
	if(open(SAVE, ">dump_uploads/$file")){	#create a new temp file on the server
		my $data;
		my $totalsize = 0;
		while(my $size = read($form{'dumpfile'}, $data, 1024)){	#read the contents of the file
			print SAVE $data;
			$totalsize += $size;	#save the size of this file
		}
		close SAVE;
		if($totalsize > 0){$result = 1;}	#got a valid file
		else{
			unlink("dump_uploads/$file");
			$error = "File: $file was empty";
		}
	}
	else{$error = "Could not save file: $file";}
	return $result;
}
###############################################################################################################################
sub processFile{
	my $file = shift;
	if(open(DUMP, "<dump_uploads/$file")){
		my @allSql;	#this is where all the commands will be stored
		my $count = 0;	#this counts the commands found
		while(<DUMP>){
			chomp $_;
			$_ =~ s/\r//g;	#get rid of all trace of dos
			if($_ !~ m/^(--|#)/ && $_ ne ""){	#read all of the file in excluding comments and blank lines
				if($_ =~ m/;$/){	#this a whole command or the end of one
					$allSql[$count] .= $_;
					$count++;
				}
				else{$allSql[$count] .= $_;}	#it is the first or middle part of a command
			}
		}
		close(DUMP);
		my $dbh = DBI -> connect("DBI:mysql:database=$form{'database'};host=$form{'host'}", $form{'user'}, $form{'password'});	#connect once incase we need to change databases
		if($dbh){
			foreach (@allSql){	#execute all of the commands
				if($_ =~ m/^\w/){	#queries must start with a word
					if(!$dbh -> do($_)){	#throw an error and end the loop if there is a problem with the query
						$error = "Problem with query: " . $dbh -> errstr;
						last;
					}
				}
			}
			return $count;
		}
		else{$error = "Cant connect to MySQL server: " . $DBI::errstr;}
	}
	else{$error = "Could not read dump file: $0";}
	return undef;
}
##################################################################################################################
sub createInsertForm{
	my($host, $user, $password, $database, $table) = @_;
	my $dbh = DBI -> connect("DBI:mysql:database=$database;host=$host", $user, $password);
	if($dbh){
		my $query = $dbh -> prepare("DESCRIBE $table;");
		if($query -> execute()){
			my $names = $query ->{'NAME'};	#all returned field names
			my $html = "";
			my $fCount = 0;
			#print "Content-type: text\html\n\n";
			while(my @row = $query -> fetchrow_array()){
				$html .= "<tr><th valign=\"top\">$row[0]</th>";
				$html .= "<td>";
				#print "row[1] = $row[1]<br>\n";
				if($row[1] =~ m/^tinytext|text|mediumtext|longtext|tinyblob|blob|mediumblob|longblob$/){	#these types need an text area instead
					$html .= "<textarea name=\"insert_$fCount\" wrap=\"off\" cols=\"30\" rows=\"10\">";
					if($row[4]){$html .= $row[4];}	#add default value
					$html .= "</textarea>";
				}
				else{	#text type entry (defualt)
					$html .= "<input type=\"text\" name=\"insert_$fCount\" size=\"35\"";
					if($row[4]){$html .= " value=\"$row[4]\">";}	#add default value
					else{$html .= ">";}
				}
				$html .= "</td><td valign=\"top\">$row[1]</td>";				
				$html .= "</tr>\n";
				$fCount++;
			}
			$query -> finish();
			return $html;
		}
		else{$error = "Problem with query: " . $dbh -> errstr;}
		$dbh -> disconnect();
	}
	else{$error = "Cant connect to MySQL server: " . $DBI::errstr;}
	return undef;
}
##################################################################################################################
sub createDumpFile{
	if(open(EXPORT, ">dump_downloads/$form{'key'}.sql")){	#able to create the export file
		print EXPORT "#WebMySQL $VERSION dump\n\n";
		print EXPORT "#Host: $form{'host'}\n";
		print EXPORT "#Database: $form{'database'}\n";
		print EXPORT "#Server version: " . &getVariable($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, "version") . "\n\n";
		print EXPORT "CREATE DATABASE IF NOT EXISTS $form{'database'};\n";
		print EXPORT "USE $form{'database'};\n";
		if(my @tables = &getTables($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'})){
			my $dbh = DBI -> connect("DBI:mysql:database=$form{'database'};host=$form{'host'}", $form{'user'}, $form{'password'});
			if($dbh){
				for(my $tCount = 0; $tCount <= $#tables; $tCount++){	#work through all of the tables
					print EXPORT "\n#Table structure for table '$tables[$tCount]'\n";
					my $query = $dbh -> prepare("SHOW CREATE TABLE $form{'database'}.$tables[$tCount];");
					if($query -> execute()){
						my(undef, $creation) = $query -> fetchrow_array();
						$query -> finish();
						print EXPORT "$creation;\n";
					}
					else{$error = "Cant retrieve creation details $tables[$tCount] table: " . $dbh -> errstr;}
					print EXPORT "\n#Dumping data for table '$tables[$tCount]'\n";
					$query = $dbh -> prepare("SELECT * FROM $tables[$tCount];");
					if($query -> execute()){
						while(my @fields = $query -> fetchrow_array()){	#print a row at a time
							print EXPORT "INSERT INTO $tables[$tCount] VALUES(";
							for(my $f = 0; $f <= $#fields; $f++){	#loop over each field
								print EXPORT "'";
								if(defined($fields[$f])){
									$fields[$f] =~ s/'/\\'/g;	#so field values dont break out of the surrounding quotes
									print EXPORT $fields[$f];}	#only print the value if its something
								print EXPORT "'";
								if($f < $#fields){print EXPORT ", ";}	#print the field separator
							}
							print EXPORT ");\n";
						}
						$query -> finish();
					}
								
				}
				$dbh -> disconnect();
			}
			else{$error = "Cant connect to MySQL server: " . $DBI::errstr;}
		}
		close(EXPORT);
	}
	else{$error = "Unable to create export file: $!";}
}
####################################################################################################################
sub queueInsert{	#display the insert page and queue the pending insert records
	print "Content-type: text/html\n\n";
					use Data::Dumper;
					print Dumper(%form);
	if($form{'tables'} =~ m/^(\w+)$/){	#safety check on table name
		my $table = $1;
		if(my @fields = &getFields($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $form{'tables'})){
			my $rCount = 0;
			while(exists($form{'insertdata' . $rCount})){
				#print "insertdata$rCount alread exists with '" . $form{'insertdata' . $rCount} . "'<br0>\n";
			
			$rCount++;}	#find how many insert records we already have
			print "got a total of $rCount previous records<br>\n";
			$form{'insertdata' . $rCount} = "";
			for(my $fCount = 0; $fCount <= $#fields; $fCount++){	#loop through all of the fields creating an insert record
				$form{'insertdata' . $rCount} .= &toHex($form{'insert_' . $fCount}) . "�";
			}
			chop $form{'insertdata' . $rCount};	#get rid of the last separator
			$form{'input'} = &createInsertForm($form{'host'}, $form{'user'}, $form{'password'}, $form{'database'}, $table);
			$form{'fields'} = "";
			foreach(@fields){	#create the field name headings
				$_ =~ s/^$table\.//;	#we just want the field name not the table name aswell
				$form{'fields'} .= "<th>$_</th>";
			}
			$form{'fields'} .= "<th>&nbsp;</th>\n";	#make an extra column for the delete buttons
			#now show the previously stored rows
			$form{'currentrecords'} = "";
			foreach my $key (keys %form){	#search through the form/session data
				print "key $key value $form{$key}<br>\n";
				if($key =~ m/^insertdata(\d+)$/){	#found a preveious record
					if($form{$key} ne ""){	#we have some data in the current record
						my $id = $1;	#so we can delete this record
						$form{'currentrecords'} .= "<tr>";
						my @pFields = split(/�/, $form{$key});
						for(my $pCount = 0; $pCount <= $#fields; $pCount++){	#find the different fields
							if(defined($pFields[$pCount])){	#display the entered value
								$pFields[$pCount] = &fromHex($pFields[$pCount]);	#convert from hex to display
								$form{'currentrecords'} .= "<td>$pFields[$pCount]</td>";
							}
							else{$form{'currentrecords'} .= "<td>&nbsp;</td>";}	#no value entered for this field
						}
						$form{'currentrecords'} .= "<td valign=\"top\"><form action=\"$ENV{'SCRIPT_NAME'}\" method=\"post\">";
						$form{'currentrecords'} .= "<input type=\"hidden\" name=\"key\" value=\"$form{'key'}\">";
						$form{'currentrecords'} .= "<input type=\"hidden\" name=\"action\" value=\"insertremovequeued\">";
						$form{'currentrecords'} .= "<input type=\"hidden\" name=\"qid\" value=\"$id\">";
						$form{'currentrecords'} .= "<input type=\"submit\" value=\"Remove\">";
						$form{'currentrecords'} .= "</form></td></tr>\n";
					}
					else{delete($form{$key});}	#we fix our own problems here!
				}
			}
			if($form{'currentrecords'} eq ""){$form{'currentrecords'} = "<tr><td colspan=\"" . ($#fields + 1) . "\"><i>No records waiting to be inserted</i></td></tr>\n";}
			&updateKey($form{'key'});
		}
	}
	else{$error = "Table name contains invalid characters";}				
}
##################################################################################################################
sub toHex{	#converts a string to hex
	my $string = shift;
	$string =~ s/([\W|\w])/"\\x" . uc(sprintf("%2.2x",ord($1)))/eg;
	return $string;
}
##################################################################################################################
sub fromHex{	#converts from hex to ASCII
	my $string = shift;
	$string =~ s/\\x([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
	return $string;
}
##################################################################################################################
sub displaySQL{	#safely formats sql for displaying in a browser
	my $sql = shift;
	$sql =~ s/</&lt;/g;
	$sql =~ s/>/&gt;/g;	
	$sql =~ s/\n/<br>/g;
	return $sql;
}