#the dumb terminal webmysql module
#mt 29/11/2003 2.5	updated getDatabases sub incase "SHOW DATABASES" is disabled
#mt 14/03/2005	2.7	added explainquery function
#							added runqueryvert function
package Plack::App::WebMySQL::Sql;
BEGIN {
    use Plack::App::WebMySQL;
    use Exporter();
    @ISA = qw(Exporter);
    @EXPORT = qw(dbConnect
                     testConnect
					 getTables
					 getFields
					 getFieldsShort
					 getDatabases
					 runQuery
					 getTableRows
					 runNonSelect
					 getVariable
					 explainQuery
					 runQueryVert);
}
##################################################################################################
sub dbConnect{    #connect to db server
    my($database, $host, $user, $password) = @_;
    my $dbh = DBI->connect("DBI:MariaDB:database=$database;host=$host", $user, $password);
    die("Cant connect to MySQL server: " . $DBI::errstr) unless $dbh;
    return $dbh;
}
############################################################################################################
sub testConnect{	#tests if we can connect to the mysql server
	my($host, $user, $password, $database) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	$dbh->disconnect();
	1;
}
##########################################################################################################
sub getTables{	#returns an array of tables for the current database
	my($host, $user, $password, $database) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my $query = $dbh->prepare("SHOW TABLES;");
	if($query->execute()){
		my @tables;
		while(my $table = $query->fetchrow_array()){push(@tables, $table);}	#create an array of the tables found
		$query->finish();
        $dbh->disconnect();
		return @tables;	#send back the tables to the calling sub
	}
	die("Cant find table list: " . $dbh->errstr);
}
##########################################################################################################
sub getFields{	#returns an array of fields for the current table
	my($host, $user, $password, $database, $tables) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my @fields;
	foreach(split(/, /, $tables)){	#get the fields for all of the selected tables
		my $query = $dbh->prepare("DESCRIBE $_;");
		if($query->execute()){
			while(my @dInfo = $query->fetchrow_array()){push(@fields, "$_.$dInfo[0]");}	#create an array of the fields found
			$query->finish();
		}
		else{
			die("Cant retrieve fields list for $_ table: " . $dbh->errstr);
		}
	}
    $dbh->disconnect();
    return @fields;
}
##########################################################################################################
sub getFieldsShort{	#returns an array of fields for the current table not includung the table name
	my($host, $user, $password, $database, $tables) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my @fields;
	foreach(split(/, /, $tables)){	#get the fields for all of the selected tables
		my $query = $dbh->prepare("DESCRIBE $_;");
		if($query->execute()){
			while(my @dInfo = $query->fetchrow_array()){push(@fields, $dInfo[0]);}	#create an array of the fields found
			$query->finish();
		}
		else{
			die("Cant retrieve fields list for $_ table: " . $dbh->errstr);
		}
	}
	$dbh->disconnect();
	return @fields;	#send back the fields to the calling sub
}
##########################################################################################################
sub getDatabases{	#returns an array of databases for the current connection
	my($host, $user, $password, $database) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my @dbs;
	my $query = $dbh->prepare("SHOW DATABASES;");
	if($query->execute()){
		while(my $db = $query->fetchrow_array()){push(@dbs, $db);}	#create an array of the tables found
		$query->finish();
	}
	else{	#try to the databases from the grant command
		$query = $dbh->prepare("SHOW GRANTS FOR $user\@$host;");
		if($query->execute()){
			while(my $perm = $query->fetchrow_array()){
				if($perm =~ m/^GRANT .+ ON (.+)\..+ TO '$user'\@'$host'$/){push(@dbs, $1);}	#create an array of the tables found
			}
			$query->finish();
		}
		else{push(@dbs, $database);}	#SHOW DATABASE did not work so just return the current database
	}
	$dbh->disconnect();
	return @dbs;	#send back the tables to the calling sub
}
##################################################################################################################
sub runQuery{
	my($host, $user, $password, $database, $code) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my $query = $dbh->prepare($code);
	if($query->execute()){
		my $html = "<tr>";
		my $names = $query->{'NAME'};	#all returned field names
		for(my $i = 0;  $i < $query->{'NUM_OF_FIELDS'};  $i++){$html .= "<th>$$names[$i]</th>";}	#get field names
		$html .= "</tr>\n";	#finished field names
		while(my @fields = $query->fetchrow_array()){
			$html .= "<tr bgcolor=\"#FFFFFF\">";
			foreach(@fields){
				if($_){	#this field has a value
					$_ =~ s/</&lt;/g;	#html dont like less than signs
					$_ =~ s/>/&gt;/g;	#html dont like greater than signs
					$html .= "<td>$_</td>";
				}
				else{$html .= "<td>&nbsp;</td>";}	#this field has a null value
			}
			$html .= "</tr>\n";
		}
		$html .= "<tr><td align=\"center\" colspan=\"" . $query->{'NUM_OF_FIELDS'} . "\">" . $query->rows() . "Rows found</td></tr>\n";	#print rows found
		$query->finish();
        $dbh->disconnect();
		return $html;
	}
	die("Problem with query: " . $dbh->errstr);
}
##########################################################################################################
sub getTableRows{	#returns how many rows in a table
	my($host, $user, $password, $database, $table) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my $query = $dbh->prepare("SELECT COUNT(*) FROM $table;");
	my $rows;
	if($query->execute()){
		$rows = $query->fetchrow_array();
		$query->finish();
        $dbh->disconnect();
        return $rows;
	}
	die("Cant retrieve number of rows for $_ table: " . $dbh->errstr);
}
#############################################################################################################
sub runNonSelect{
	my($host, $user, $password, $database, $code) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my $affected;
	if(!($affected = $dbh->do($code))){
		die("Problem with query: " . $dbh->errstr);
	}
	$dbh->disconnect();
	return $affected;
}
##########################################################################################################
sub getVariable{	#returns a server variable
	my($host, $user, $password, $database, $var) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my $value = "";
	my $query = $dbh->prepare("SHOW VARIABLES LIKE '$var';");
	if($query->execute()){
		(undef, $value) = $query->fetchrow_array();
		$query->finish();
        $dbh->disconnect();
        return $value;  #send back the fields to the calling sub
	}
	die("Cant retrieve variable for $var: " . $dbh->errstr);
}
##################################################################################################################
sub explainQuery{
	my($host, $user, $password, $database, $code) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my $query = $dbh->prepare("EXPLAIN " . $code);
	if($query->execute()){
		my $html = "<tr>";
		my $names = $query->{'NAME'};	#all returned field names
		for(my $i = 0;  $i < $query->{'NUM_OF_FIELDS'};  $i++){$html .= "<th>$$names[$i]</th>";}	#get field names
		$html .= "</tr>\n";	#finished field names
		while(my @fields = $query->fetchrow_array()){
			$html .= "<tr bgcolor=\"#FFFFFF\">";
			foreach(@fields){
				if($_){	#this field has a value
					$_ =~ s/</&lt;/g;	#html dont like less than signs
					$_ =~ s/>/&gt;/g;	#html dont like greater than signs
					$html .= "<td>$_</td>";
				}
				else{$html .= "<td>&nbsp;</td>";}	#this field has a null value
			}
			$html .= "</tr>\n";
		}
		$html .= "<tr><td align=\"center\" colspan=\"" . $query->{'NUM_OF_FIELDS'} . "\">" . $query->rows() . "Rows found</td></tr>\n";	#print rows found
		$query->finish();
        $dbh->disconnect();
		return $html;
	}
	die("Problem with query: " . $dbh->errstr);
}
##################################################################################################################
sub runQueryVert{	#displays results verticaly
	my($host, $user, $password, $database, $code) = @_;
	my $dbh = dbConnect($database, $host, $user, $password);
	my $query = $dbh->prepare($code);
	if($query->execute()){
		my $html = "";
		my $names = $query->{'NAME'};	#all returned field names
		my @rows;
		for(my $i = 0;  $i < $query->{'NUM_OF_FIELDS'};  $i++){
			$rows[$i] = "<tr bgcolor=\"#FFFFFF\"><th>$$names[$i]</th>";
		}	#get field names
		#$html .= "</tr>\n";	#finished field names
		while(my @fields = $query->fetchrow_array()){
			for(my $rCount = 0; $rCount <= @fields; $rCount++){
				if($fields[$rCount]){	#this field has a value
					$fields[$rCount] =~ s/</&lt;/g;	#html dont like less than signs
					$fields[$rCount] =~ s/>/&gt;/g;	#html dont like greater than signs
					$rows[$rCount] .= "<td>$fields[$rCount]</td>";
				}
				else{$row[$rCount] .= "<td>&nbsp;</td>";}	#this field has a null value
			}
		}
		for(my $i = 0;  $i < $query->{'NUM_OF_FIELDS'};  $i++){
			$rows[$i] .= "</tr>";
		}
		#$html .= "<tr><td align=\"center\" colspan=\"" . $query->{'NUM_OF_FIELDS'} . "\">" . $query->rows() . "Rows found</td></tr>\n";	#print rows found
		$query->finish();
        $dbh->disconnect();
		$html = join("", @rows);
		return $html;
	}
	die("Problem with query: " . $dbh->errstr);
}
###############################################################################
return 1;
END {}
