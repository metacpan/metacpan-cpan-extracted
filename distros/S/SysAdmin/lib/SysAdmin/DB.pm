
package SysAdmin::DB;
use Moose;
use Moose::Util::TypeConstraints;

extends 'SysAdmin';
use locale;
use DBI;

our $VERSION = 0.09;


subtype 'CheckSupportedDBDriver'
  => as 'Str'
  => where { SysAdmin::DB::_check_supported_db_driver($_) }
  => message { SysAdmin::DB::_driver_error($_) };

has 'db'          => (isa => 'Str', is => 'rw', required => 1);
has 'db_driver'   => (isa => 'CheckSupportedDBDriver', is => 'rw', required => 1);

has 'db_username' => (isa => 'Str', is => 'rw');
has 'db_password' => (isa => 'Str', is => 'rw');
has 'db_host'     => (isa => 'Str', is => 'rw', default => "localhost");
has 'db_port'     => (isa => 'Str', is => 'rw');

__PACKAGE__->meta->make_immutable;

my @currently_supported_drivers = ("mysql","Oracle","Pg","SQLite");

sub fetchTable {

	my ($self,$db_select) = @_;
	
	my $db_driver = SysAdmin::DB::_check_supported_db_driver($self->db_driver);
	
	my $table = undef; ## For return value
	
	## If $db_select is defined
	if($db_select){
		
		## Converts to lower case to verify if its a SELECT SQL statement.
		if($db_select =~ /select\s.*/i){
			
			##
			## Mostly taken from DBI/DBD module examples. 
			## Works in most DB table extractions.
			##
			
			my $dbh = SysAdmin::DB::_proper_dbh_select($self);
			
			my $sth = $dbh->prepare($db_select) or die "Couldn't prepare statement!!!";
			$sth->execute() or die ("Cannot execute statement!!!");
			
			$table = $sth->fetchall_arrayref;
			
			$sth->finish;
			
			if($db_driver ne "SQLite"){
				$dbh->disconnect;
			}
			
			return $table;
		}
		else{
			Carp::croak "## WARNING ##\nCurrently, \"SELECT\" SQL Statements supported!";
		}
	}
	else{
		Carp::croak "## WARNING ##\nNo \"SELECT\" SQL Statement supplied!";
	}
}

sub fetchRow {
	
	my ($self,$db_select) = @_;
	
	my $db_driver = SysAdmin::DB::_check_supported_db_driver($self->db_driver);
	
	my $row = undef; ## For return value
	
	## If $db_select is defined
	if($db_select){
		
		## Converts to lower case to verify if its a SELECT SQL statement.
		if($db_select =~ /select\s.*/i){
			
			##
			## Mostly taken from DBI/DBD module examples. 
			## Works in most DB table extractions.
			##
			
			my $dbh = SysAdmin::DB::_proper_dbh_select($self);
			
			$row = $dbh->selectrow_array("$db_select");
			
			if($db_driver ne "SQLite"){
				$dbh->disconnect;
			}
			
			return $row;
			
		}
		else{
			Carp::croak "## WARNING ##\nCurrently, \"SELECT\" SQL Statements supported!";
		}
	}
	else{
		Carp::croak "## WARNING ##\nNo \"SELECT\" SQL Statement supplied!";
	}
}

## Find better name
sub _manipulateData {
	
	my ($self,$db_insert,$attributes_ref) = @_;
	
	## $attributes_ref must not be empty!!!
	
	my $db_driver = SysAdmin::DB::_check_supported_db_driver($self->db_driver);
	
	## If $db_select is defined
	if($db_insert){
		
		## Converts to lower case to verify if its a INSERT/UPDATE/DELETE SQL statement.
		if(($db_insert =~ /insert\s.*/i) || ($db_insert =~ /update\s.*/i) || ($db_insert =~ /delete\s.*/i)){
			
			## Matches SQLs with ? for substitution
			#if($db_insert =~ /.*[\(\,\=]\s*\?.*/i){}
			
			## Matches SQLs with ? within ''
			#if($db_insert =~ /.*\(\'.*\?.*\'.*\).*/i){}
				
			## Assumes using "?" for attribute substitution.
			if($attributes_ref){
				
				## Checks array lenght, to verify if it has values for transaction insert
				my $attributes_ref_length = @$attributes_ref;
					
				if($attributes_ref_length != 0){
					
					## Database handler
					my $dbh_with_attributes = SysAdmin::DB::_proper_dbh_insert($self);
					
					## Return ID of last insert
					my $last_id_inserted_with_attributes = undef;
					
					eval {
						my $sth_with_attributes = $dbh_with_attributes->prepare($db_insert) or die "Couldn't prepare statement!!!";
						$sth_with_attributes->execute(@$attributes_ref) or die "Cannot execute statement!!!";
						
						## Use regex to get table name from insert SQL
						if($db_insert =~ /insert into (\w+)\s.*/i){
							$last_id_inserted_with_attributes = SysAdmin::DB::_fetchLastId($self,$dbh_with_attributes,$1);
						}
						
						$sth_with_attributes->finish;
					};
					
					if ($@) {
						$dbh_with_attributes->rollback();
						die $@;
					}
					
					if($db_driver ne "SQLite"){
						$dbh_with_attributes->disconnect;
					}
					
					return $last_id_inserted_with_attributes;
				}
			}
			
			## Should match SQLs without ? for substitution
			## Taking risk in using regex for this match
			
			elsif($db_insert !~ /.*[\(\,\=]\s*\?.*/i){
				
				## Database handler
				my $dbh_without_attributes = SysAdmin::DB::_proper_dbh_insert($self);
				
				## Return ID of last insert
				my $last_id_inserted_without_attributes = undef;
				
				my $sth_without_attributes = $dbh_without_attributes->prepare($db_insert) or die "Couldn't prepare statement!!!";
				$sth_without_attributes->execute() or die "Cannot execute statement!!!";
				
				## Use regex to get table name from insert SQL
				if($db_insert =~ /insert into (\w+)\s.*/i){
					$last_id_inserted_without_attributes = SysAdmin::DB::_fetchLastId($self,$dbh_without_attributes,$1);
				}
				
				$sth_without_attributes->finish;
				
				if($db_driver ne "SQLite"){
					$dbh_without_attributes->disconnect;
				}
				
				return $last_id_inserted_without_attributes;
				
			}
			else{
				Carp::croak "## WARNING ##\nNo valid attributes defined for Insert/Update/Delete!";
			}
		}
	}
}

sub insertData {
	
	my ($self,$db_insert,$attributes_ref) = @_;
	
	SysAdmin::DB::_manipulateData($self,$db_insert,$attributes_ref);
}

sub updateData {
	
	my ($self,$db_update,$attributes_ref) = @_;
	
	SysAdmin::DB::_manipulateData($self,$db_update,$attributes_ref);
}

sub deleteData {
	
	my ($self,$db_delete,$attributes_ref) = @_;
	
	SysAdmin::DB::_manipulateData($self,$db_delete,$attributes_ref);
}

sub _fetchLastId {
	my ($self,$dbh,$db_table) = @_;
	
	my $db_driver_input = $self->db_driver;
	
	my $db_driver = SysAdmin::DB::_check_supported_db_driver($db_driver_input);
	
	my $last_insert_id = $dbh->last_insert_id(undef,undef,"$db_table",undef);
	
	return $last_insert_id;
}

sub _default_db_ports {
	my ($driver) = @_;
	
	my %supported_ports = ("Pg"     => "5432",
		                   "mysql"  => "3306",
						   "Oracle" => "1521");

	return $supported_ports{$driver};
}

sub _check_supported_db_driver {
	
	my ($driver) = @_;
	
	## Test for supported Drivers
	my $user_input = lc($driver);
	
	my %supported_drivers = ("pg"     => "Pg",
		                     "mysql"  => "mysql",
						     "sqlite" => "SQLite",
							 "oracle" => "Oracle");

	return $supported_drivers{$user_input};
}

sub _proper_dbh_select {
	my ($self) = @_;
	
	my $db_database     = $self->db;
	my $db_username     = $self->db_username;
	my $db_password     = $self->db_password;
	my $db_host         = $self->db_host;
	my $db_port         = $self->db_port;
	my $db_driver_input = $self->db_driver;
	
	my $db_driver = SysAdmin::DB::_check_supported_db_driver($db_driver_input);
	
	my $dbh = undef;
	
	if($db_driver eq "SQLite"){
		$dbh = DBI->connect("dbi:SQLite:$db_database") 
							or die "Could not connect to $db_database";
	}
	elsif($db_driver eq "Oracle"){
		$dbh = DBI->connect("dbi:Oracle:$db_database", $db_username,$db_password) 
							or die "Could not connect to $db_database";
	}
	else{
		## MySQL and PostgreSQL use similar syntax
		$dbh = DBI->connect("dbi:$db_driver:dbname=$db_database;host=$db_host;port=$db_port;",
			                "$db_username","$db_password") or die "Could not connect to $db_database";
	}
	
	return $dbh;
}

sub _proper_dbh_insert {
	my ($self) = @_;
	
	my $db_database     = $self->db;
	my $db_username     = $self->db_username;
	my $db_password     = $self->db_password;
	my $db_host         = $self->db_host;
	my $db_port         = $self->db_port;
	my $db_driver_input = $self->db_driver;
	
	my $db_driver = SysAdmin::DB::_check_supported_db_driver($db_driver_input);
	
	## Database handler
	my $dbh = undef;
	
	if($db_driver eq "SQLite"){
		$dbh = DBI->connect("dbi:SQLite:$db_database",
							{ AutoCommit => 1 }) or die "Could not connect to $db_database";
	}
	elsif($db_driver eq "Oracle"){
		$dbh = DBI->connect("dbi:Oracle:$db_database", 
							$db_username,$db_password,
							{ AutoCommit => 1 }) or die "Could not connect to $db_database";
	}
	else{
		## MySQL and PostgreSQL use similar syntax
		$dbh = DBI->connect("dbi:$db_driver:dbname=$db_database;host=$db_host;port=$db_port;",
							"$db_username","$db_password",
							{ RaiseError => 0, AutoCommit => 1 }) or die "Could not connect to $db_database";
	}
	
	return $dbh;
}

sub _driver_error {

	my ($error) = @_;
	
	my $error_to_return = undef;

		$error_to_return = <<END;

## WARNING ##

This driver "$error" is currently not supported!

Please use:

@currently_supported_drivers

END
	
	return $error_to_return . "Error";

}

sub clear {
	my $self = shift;
	
	$self->db(0);
	$self->db_username(0);
	$self->db_password(0);
	$self->db_host(0);
	$self->db_port(0);
	$self->db_driver(0);
	
}

1;
__END__

=head1 NAME

SysAdmin::DB - Perl DBI/DBD wrapper module..

=head1 SYNOPSIS

  ## Example using PostgreSQL Database
	
  use SysAdmin::DB;
	
  my $db = "dbd_test";
  my $username = "dbd_test";
  my $password = "dbd_test";
  my $host = "localhost";
  my $port = '5432';
  my $driver = "pg"; ## Change to "mysql" for MySQL connection
	
  ### Database Table
  ##
  # create table status(
  # id serial primary key,
  # description varchar(25) not null);
  ##
  ###
	
  my $dbd_object = new SysAdmin::DB(db          => $db,
                                    db_username => $username,
                                    db_password => $password,
                                    db_host     => $host,
                                    db_port     => $port,
                                    db_driver   => $driver);
  ###
  ## DB and DB_DRIVER are always required!
  ###
	
  ###
  ## For databases that need username and password (MySQL, PostgreSQL),
  ## DB_USERNAME and DB_PASSWORD are also required
  ###
	
  ### For SQLite, simply declare DB and DB_DRIVER, example:
  ##
  ## my $db = "/tmp/dbd_test.db";
  ## my $dbd_object = new SysAdmin::DB(db        => $db,
  ##                                   db_driver => sqlite);
  ##
  ###
	
	
  ###
  ## Work with "$dbd_object"
  ###
	
  ### Insert Data
	
  ## SQL Insert statement
  my $insert_table = qq(insert into status (description) values (?));
	
  ## Insert Arguments, to subsitute "?"
  my @insert_table_values = ("DATA");
	
  ## Insert data with "insertData"
	
  $dbd_object->insertData("$insert_table",\@insert_table_values);
	
  ## By declaring a variable, it returns the last inserted ID
	
  my $last_insert_id = $dbd_object->insertData("$insert_table",\@insert_table_values);
	
  ## The insertData Method could also be expressed the following ways
  
  my $insert_table_values = ["Data"];
  $dbd_object->insertData("$insert_table",$insert_table_values);
  
  # or
  
  $dbd_object->insertData("$insert_table",["Data"]);
	

  ### Select Table Data
	
  ## SQL select statement
  my $select_table = qq(select id,description from status);
	
  ## Fetch table data with "fetchTable"
  my $table_results = $dbd_object->fetchTable("$select_table");
	
  ## Extract table data from $table_results array reference
  foreach my $row (@$table_results) {
	
	my ($db_id,$db_description) = @$row;
	
	## Print Results
	print "DB_ID $db_id, DB_DESCRIPTION $db_description\n";
	
  }
	
	
  ### Select Table Row
	
  ## SQL Stament to fetch last insert
  my $fetch_last_insert = qq(select description 
                             from status 
                             where id = $last_insert_id);
	
  ## Fetch table row with "fetchRow"
  my $row_results = $object->fetchRow("$fetch_last_insert");
	
  ## Print Results
  print "Last Insert: $row_results\n";
				    

=head1 DESCRIPTION

This is a sub class of SysAdmin. It was created to harness Perl Objects and keep
code abstraction to a minimum.

SysAdmin::DB uses perl's DBI and DBD to interact with database.

Currently DBD::Pg, DBD::mysql and DBD::SQLite are supported.

=head1 METHODS

=head2 C<new()>

	my $dbd_object = new SysAdmin::DB(db          => $db,
                                      db_username => $username,
                                      db_password => $password,
                                      db_host     => $host,
                                      db_port     => $port,
                                      db_driver   => $driver);

Creates SysAdmin::DB object instance. Used to declare the database connection
information.

	db => $db

State database name to connect to
	
	db_username => $username
	
State a privileged user to connect to the C<DB> database
	
	db_password => $password,
	
State a privileged user's password to connect to the C<DB> database
	
	db_host => $host

State the IP address/Hostname of the database server

	db_port => $port
	
State the listening port of the database server. PostgreSQL 5432, MySQL 3306

	db_driver => $driver

State the database driver to use. Currently supported: Pg, mysql and SQLite

=head2 C<insertData()>

	## SQL Insert statement
	my $insert_table = qq(insert into status (description) values (?));
	
	## Insert Arguments, to subsitute "?"
	my @insert_table_values = ("DATA");
	
	## Insert data with "insertData"
	
	$dbd_object->insertData("$insert_table",\@insert_table_values);
	
	## By declaring a variable, it returns the last inserted ID
	
	my $last_insert_id = $dbd_object->insertData("$insert_table",\@insert_table_values);
	
=head2 C<fetchTable()>	

	## Select Table Data
	
	## SQL select statement
	
	my $select_table = qq(select id,description from status);
	
	## Fetch table data with "fetchTable"
	
	my $table_results = $dbd_object->fetchTable("$select_table");
	
	## Extract table data from $table_results array reference
	
	foreach my $row (@$table_results) {
	
		my ($db_id,$db_description) = @$row;
	
		## Print Results
		print "DB_ID $db_id, DB_DESCRIPTION $db_description\n";
	
	}

=head2 C<fetchRow()>

	## Select Table Row
	
	## SQL Stament to fetch last insert
	my $fetch_last_insert = qq(select description 
                               from status 
                               where id = $last_insert_id);
	
	## Fetch table row with "fetchRow"
	
	my $row_results = $object->fetchRow("$fetch_last_insert");
	
	## Print Results
	print "Last Insert: $row_results\n";

=head1 SEE ALSO

DBI - Database independent interface for Perl

DBD::Pg - PostgreSQL database driver for the DBI module

DBD::MySQL - MySQL driver for the Perl5 Database Interface (DBI)

DBD::SQLite - Self Contained RDBMS in a DBI Driver

=head1 AUTHOR

Miguel A. Rivera

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
