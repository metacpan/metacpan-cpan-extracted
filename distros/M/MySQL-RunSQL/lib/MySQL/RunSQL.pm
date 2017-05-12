package MySQL::RunSQL;

=head1 NAME

MySQL::RunSQL	- Run SQL queries against a MySQL database and return the
results to STDOUT or XLSX file.

=cut

use v5.10;
use warnings;
use Modern::Perl;
use DBI;
use Params::Validate;
use Excel::Writer::XLSX;
use Env						qw/HOME/;
use vars					qw($VERSION @ISA);

require Exporter;

@ISA = qw/Exporter/;
$VERSION = '1.2';


=head1 SYNOPSIS

	use MySQL::RunSQL;
	
	my $runsql = MySQL::RunSQL->new(
		group_name => <mysql_group>, #[blockname] to look under in my.cnf file
		database => <database>, # Database to run query against
		my_cnf => <my_cnf_file>, # File the contains user/pass information
		host	=> <mysql_server> # MySQL server to connect to
		);
		
	my $sqlfile = 	"/tmp/employees.sql";
	
	$runsql->runsql("SELECT col1 as 'Col 1', col2 as 'Col 2'...");
	$runsql->runsql_fromfile($sqlfile);
	
	my $xlsx = $runsql_report("SELECT col1 as 'Col 1', col2 as 'Col 2'...");
	my $xlsx = $runsql_report_fromfile($sqlfile);
	
	

=head1 DESCRIPTION

	MySQL::RunSQL provides a simple object oriented interface to
	DBD::mysql for running a queries against a MySQL database. Data
	is returned to STDOUT as a comma delimited list or is written
	out to an XLSX file.
	
=head1 EXAMPLE

	#!/usr/bin/perl
	
	use strict;
	use MySQL::RunSQL;
	use Env qw/HOME/;
	
	my $db = "test";
	my $cnf = "$HOME/.my.cnf";
	my $group = "test";
	my $host = "localhost";
	
	# Create our MySQL::RunSQL Object
	my $rs = MySQL::RunSQL->new(
		database =>	$db,
		my_cnf	=>	$cnf,
		group_name => $group,
		host =>	$host
	);
	
	# The report will use the as "NAME" as the header for the column
	#if this is omitted then it will use the column identifier
	
	my $sql = <<"SQL";
	SELECT employee_id as 'ID',  CONCAT(first_name,' ', last_name) as 'Name',
	address as 'Address'
	FROM emloyeeDB
	WHERE start_date like "%2002%"
SQL
	
	# Run the report & write out to excel
	my $report = $rs->runsql_report->($sql);
	
	# Print the file location
	print "\n\tYour report is ready: $report\n\n";
	
	exit 0;

=head1 METHODS

=head2 MySQL::RunSQL->new(
									database => $db,
									my_cnf => $mycnf,
									group_name => $mygroup,
									host => $mysqlhost,
									port => $mysqlport
								);

Returns a MySQL::RunSQL object. The new method is invoked with the following
options:

	host		=> mysql_server
	database	=> database	 
	port		=> mysql port	default=3306
	my_cnf		=> mysql my.cnf file with both user & password set
	group_name	=> under which [group] in the my.cnf file can the 
				login information be found
					
	host, database, my_cnf, & group_name are all required.
	
=cut


sub new {
	my $class = shift;
	
	#Verify parameters
	my %args = validate (
		@_,
		{
			# all parameters are required, accept port which defaults to 3306
			database => 1,
			group_name => 1,
			my_cnf	=>	1,
			host	=>	1,
			port	=> { default => 3306 }
		}
	);
	
	
	my $self = {};

	my %dbparams = ( RaiseError => 1, PrintError => 1 );
	
	my $dsn = "DBI:mysql:database=$args{'database'};host=$args{'host'};"
			. "port=$args{'port'};mysql_read_default_group=$args{'group_name'};"
			. "mysql_read_default_file=$args{'my_cnf'};mysql_compression=1";
			
	my $user;
	my $password;
	
	#Connect to the server and share the db handle with the rest of the package	
	#my $dbh = DBI->connect($dsn, $user, $password, { %dbparams } );
	my	$dbh = DBI->connect($dsn, $user, $password, \%dbparams  );
		die $DBI::errstr unless $dbh;
	
	# Share the db handle with the rest of our package	
	$self->{'dbh'} = $dbh;
	
	
	return bless ($self, $class);	
}

=head2 MySQL::RunSQL->runsql("SELECT STATEMENT")

Takes a sql query and prints to STDOUT a comma delimited list of rows returned

=cut

sub runsql {
	my ($self, $sql) = @_;
	
	my $sth = $self->{'dbh'}->prepare($sql) or die $self->{'dbh'}->errstr;
	$sth->execute() or die $sth->errstr;
	
	while ( my @data = $sth->fetchrow_array )
	{
		say join(",", @data);
	}
	
	$sth->finish;
	
	return $self;
}


=head2 MySQL::RunSQL->runsql_fromfile($sqlfile);

Takes a file containing a sql query and prints to STDOUT a comma delimited
list of rows returned.
	
	
=cut

sub runsql_fromfile {
	my ($self, $file) = @_;
	
	my $sql;

	# Slurp file contents into $sql	
	eval {
		use autodie;
		
		local ( $/, *FH );
		open FH, "<", $file;
		$sql = <FH>;
		close FH;
	};
	
	given ($@) {
		when (undef) { continue; }
		when ('open') { die "Error opening file: $@\n"; }
		when (':io') { die "IO Error: $@\n"; }
		when (':all') { die "Unknown Error: $@\n"; }
	}
	
	$self->runsql($sql);
	
	return $self;
}


=head2 MySQL::RunSQL->runsql_report("SELECT STATEMENT...")

Takes a sql query and prints output to an xlsx file. Returns the file
name and location.
	
=cut

sub runsql_report {
	my ($self, $sql ) = @_;
	
	my $file = "/tmp/runsql_report.$$.xlsx";
	
	my $workbook = Excel::Writer::XLSX->new($file);
	my $worksheet = $workbook->add_worksheet("runsql_report");
	
	my $format = $workbook->add_format();
	$format->set_bold();
	$format->set_align('center');
	
	my $sth = $self->{'dbh'}->prepare($sql) or die $self->{'dbh'}->errstr;
	$sth->execute() or die $sth->errstr;
	
	my $headers = $sth->{'NAME'};
	
	my $row = 0;
	my $col = 0;
	
	foreach (@{$headers})
	{
		$worksheet->write($row, $col, $_, $format);
		$col++;
	}
	
	while (my @data = $sth->fetchrow_array)
	{
		$row++;
		$col = 0;
		
		foreach (@data)
		{
			$worksheet->write($row, $col, $_);
			$col++;
		}
	}
	
	$sth->finish;
	$workbook->close();
	
	return $file;
}


=head2 MySQL::RunSQL->runsql_report_fromfile($sqlfile)

Takes a file containing a sql query and prints output to an xlsx
file and returns the file location
	
	
=cut

sub runsql_report_fromfile {
	my ($self, $file ) = @_;
	
	my $sql;
	
	# Slurp file contents into $sql	
	eval {
		use autodie;
		
		local ( $/, *FH );
		open FH, "<", $file;
		$sql = <FH>;
		close FH;
	};
	
	given ($@) {
		when (undef) { continue; }
		when ('open') { die "Error opening file: $@\n"; }
		when (':io') { die "Error from io: $@\n"; }
		when (':all') { die "Unknown error: $@\n"; }
	}
		
	$self->runsql_report($sql);
	
	return $self;
}

# Clean up.. if we have a connection to the database - disconnect! :)
sub DESTROY {
	my ($self) = @_;
	
	if (exists $self->{'dbh'}) { $self->{'dbh'}->disconnect; }
	
	return $self;
}

1;

__END__


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 AUTHOR

Melissa A. VandenBrink, C<< <geeklady@cpan.org> >>

=head1 SEE ALSO

MySQL Database http://www.mysql.con/ 

=cut
