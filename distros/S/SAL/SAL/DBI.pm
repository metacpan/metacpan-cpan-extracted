package SAL::DBI;

# This module is licensed under the FDL (Free Document License)
# The complete license text can be found at http://www.gnu.org/copyleft/fdl.html
# Contains excerpts from various man pages, tutorials and books on perl
# DBI ABSTRACTION

use strict;
use DBI;
use Carp;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = '3.03';
	@ISA = qw(Exporter);
	@EXPORT = qw();
	%EXPORT_TAGS = ();
	@EXPORT_OK = qw();
}
our @EXPORT_OK;

END { }

=pod

=head1 Name

SAL::DBI - Database abstraction for SAL

=head1 Synopsis

 use SAL::DBI;

 my $dbo_factory = new SAL::DBI;
 my $dbo_sqlite = $dbo_factory->spawn_sqlite($filename);
 my $dbo_mysql = $dbo_factory->spawn_mysql($server, $user, $pass, $database);
 my $dbo_odbc = $dbo_factory->spawn_odbc($dsn, $user, $pass);
 my $dbo_temp = $dbo_factory->spawn_sqlite(':memory:');

 # SQL Queries
 my $rv = $dbo_temp->do(qq|CREATE TABLE SomeTable(some_column varchar(255), some_other_column varchar(255))|);
 my ($w, $h) = $dbo_temp->execute('SELECT * FROM SomeTable WHERE some_column=?', $somevalue);

 # Processing Records
 for (my $i=0; $i<=$h; $i++) {
	# Accessing the data directly...
 	my $field_0 = $dbo_temp->{data}->[$i][0];
 	my $field_1 = $dbo_temp->{data}->[$i][1];

	# Grab the fields as a list
	my @record = $dbo_temp->get_row($i);
 }

 # Processing entire columns
 for (my $i=0; $i<$w; $i++) {
	my @column = $dbo_temp->get_column($i);
	# do something with the data...
 }

=head1 Eponymous Hash

This section describes some useful items in the SAL::DBI eponymous hash.  Arrow syntax is used here for readability, 
but is not strictly required.

Note: Replace $SAL::DBI with the name of your database object... eg. $dbo_temp->{connection}->{dbh}

=over 1

=item Connection Information

 $SAL::DBI->{connection}->{dbh} contains the DBI database handle.
 $SAL::DBI->{connection}->{sth} contains the DBI statement handle.

=item Formatting Control

 $SAL::DBI->{fields}->[$col]{name} contains the name of the field.  (an alias for {fields}{label})
 $SAL::DBI->{fields}->[$col]{label} contains the name of the field. (an alias for {fields}{name})
 $SAL::DBI->{fields}->[$col]{type} contains the datatype for the field
 $SAL::DBI->{fields}->[$col]{visible} contains the visibility status flag for this field
 $SAL::DBI->{fields}->[$col]{writeable} contains a write-access flag.  (Use to indicate field is locked in your apps.)
 $SAL::DBI->{fields}->[$col]{css} contains a CSS string for displaying this field on the web
 $SAL::DBI->{fields}->[$col]{precision} is used to specify the number of digits to the right of a decimail place.
 $SAL::DBI->{fields}->[$col]{commify} is used to force commas in numbers > 999
 $SAL::DBI->{fields}->[$col]{align} is used for aligning the contents of the field (usually for the web).  Default is 'left';
 $SAL::DBI->{fields}->[$col]{prefix} is used to prepend a string to the contents of any data in this column.
 $SAL::DBI->{fields}->[$col]{postfix} is used to append a string to the contents of any data in this column.

=item The Dataset

 $SAL::DBI->{data}->[$y][$x] is used to access a returned dataset as if it were a two-dimensional array.
 (Yes, I'm lazy. ;-)

=back

=cut

our %DBI = (
######################################
 'connection' => {
   # Shared
	'type'		=> '',
	'dbh'		=> '',
	'sth'		=> '',
	'user'		=> '',
	'passwd'	=> '',
    # For MySQL
	'server'	=> '',
	'database'	=> '',
    # For ODBC
	'dsn'		=> '',
    # For SQLite
	'dbfile'	=> ''
  },
######################################
  'fields' => (
    {
	'name'		=> '',
	'label'		=> '',
	'type'		=> '',
	'visible'	=> '',
	'header'	=> '',
	'writeable'	=> '',
	'css'		=> '',
	'precision'	=> '',
	'commify'	=> '',
	'align'		=> '',
	'prefix'	=> '',
	'postfix'	=> '',
    }
  ),
######################################
  'data'		=> [],
######################################
 'internal' => {
	'width'		=> '',
	'height'	=> '',
  },
######################################
);

# Setup accessors via closure (from perltooc manpage)
sub _classobj {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	no strict "refs";
	return \%$class;
}

for my $datum (keys %{ _classobj() }) {
	no strict "refs";
	*$datum = sub {
		my $self = shift->_classobj();
		$self->{$datum} = shift if @_;
		return $self->{$datum};
	}
}

##########################################################################################################################
# Constructors (Public)

=pod

=head1 Constructors

=head2 new()

Builds a basic factory object.  Used for spawning database objects.

=cut

sub new {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	my $self = {};

	bless($self, $class);

	return $self;
}

=pod

=head2 spawn_mysql($server, $user, $passwd, $database)

Builds a MySQL-specific database object.

=cut

sub spawn_mysql {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;

	my $db_type = 'mysql';
	my $db_server = shift || '(undefined)';
	my $db_user = shift || '(undefined)';
	my $db_passwd = shift || '(undefined)';
	my $db_database = shift || '(undefined)';

	my $self = {};
	$self->{connection}{type} = $db_type;
	$self->{connection}{server} = $db_server;
	$self->{connection}{user} = $db_user;
	$self->{connection}{passwd} = $db_passwd;
	$self->{connection}{database} = $db_database;

	bless($self, $class);

	# make the connection
	$self->{connection}{dbh} = DBI->connect("DBI:mysql:$db_database:$db_server",$db_user,$db_passwd) || confess($DBI::errstr);

	return $self;
}

=pod

=head2 spawn_odbc($dsn, $user, $passwd)

Builds an ODBC-specific database object.

=cut

sub spawn_odbc {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;

	my $db_type = 'odbc';
	my $db_dsn = shift || '';
	my $db_user = shift || '';
	my $db_passwd = shift || '';


	my $self = {};
	$self->{connection}{type} = $db_type;
	$self->{connection}{dsn} = $db_dsn;
	$self->{connection}{user} = $db_user;
	$self->{connection}{passwd} = $db_passwd;

	bless($self, $class);

	# make the connection
	$self->{connection}{dbh} = DBI->connect("DBI:ODBC:$db_dsn",$db_user,$db_passwd) || confess($DBI::errstr);

	return $self;
}

=pod

=head2 spawn_sqlite($dbfile)

Builds a SQLite-specific database object.

Note that temporary databases can be created by passing the string ':memory:' in place of a filename.

=cut

sub spawn_sqlite {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;

	my $db_type = 'sqlite';
	my $db_server = '';
	my $db_user = '';
	my $db_passwd = '';
	my $db_database = shift || '(undefined)';

	my $self = {};
	$self->{connection}{type} = $db_type;
	$self->{connection}{server} = $db_server;
	$self->{connection}{user} = $db_user;
	$self->{connection}{passwd} = $db_passwd;
	$self->{connection}{database} = $db_database;

	bless($self, $class);

	# make the connection
	$self->{connection}{dbh} = DBI->connect("DBI:SQLite:dbname=$db_database",$db_user,$db_passwd) || confess($DBI::errstr);

	return $self;
}

##########################################################################################################################
# Destructor (Public)
sub destruct {
	my $self = shift;

	if(defined($self->{connection}{dbh})) {
		$self->{connection}{dbh}->disconnect();
	}
}

##########################################################################################################################
# Public Methods

=pod

=head1 Methods

=head2 $rv = do($statement)

Executes a SQL command that does not return a dataset.  Check $rv (result value) for errors.

=cut

sub do {
	my ($self, $statement) = @_;
	my $rv = $self->{connection}{dbh}->do($statement);
	return $rv;
}

=pod

=head2 ($w, $h) = execute($statement, @params)

Executes a SQL command that returns a dataset.  The list ($w, $h) contains the size of the SAL::DBI's internal data 
array.  (Useful in for loops ;)

=cut

sub execute {
	my ($self, $statement, @params) = @_;

	my $table = $self->_extract_table($statement);

	# From the section "Outline Usage" of the DBI pod (http://search.cpan.org/~timb/DBI-1.43/DBI.pm)
	# This should probably be it's own function...  Note also the way placeholders are used...
	$self->{connection}{sth} = $self->{connection}{dbh}->prepare($statement) || confess("Can't Prepare SQL Statement: " . $self->{connection}{dbh}->errstr);
	#

	$self->{connection}{sth}->execute(@params) || confess("Can't Execute SQL Statement: " . $self->{connection}{sth}->errstr . "\n\nSQL Statement:\n$statement\nParams:\n@params\n\n");
	$self->{data} = $self->{connection}{sth}->fetchall_arrayref();

	# get the width and height (aka metrics) of the returned data set...
	my $width = $#{$self->{data}[0]};
	my $height = $self->{connection}{sth}->rows();
	$self->{internal}{width} = $width;
	$self->{internal}{height} = $height;

	foreach my $column (0..$width) {
		$self->{fields}[$column]{visible} = 1;
		$self->{fields}[$column]{header} = 1;
		$self->{fields}[$column]{writeable} = 0;
	}

	$self->_get_labels($table);
	return ($width, $height);
}

=pod

=head2 @column = get_column($col)

Return a dataset column as a list.

=cut

sub get_column {
	my $self = shift;
	my $column = shift;
	my @data;

	for (my $i=0; $i <= $self->{internal}{height}; $i++) {
		push (@data, $self->{data}->[$i][$column]);
	}

	return @data;
}

=pod

=head2 @record = get_row($row)

Return a dataset record as a list.

=cut

sub get_row {
	my $self = shift;
	my $row = shift;
	my @data;

	for (my $i=0; $i <= $self->{internal}{width}; $i++) {
		push (@data, $self->{data}->[$row][$i]);
	}

	return @data;
}

=pod

=head2 $csv = get_csv()

Get the object's dataset as a CSV file

=cut

sub get_csv {
        my $self = shift;
        my @data;
        my @labels = $self->get_labels();
        my $labels = join(',', @labels);
        push (@data, $labels);
                                                                                                                             
                                                                                                                             
        for (my $i=0; $i < $self->{internal}{height}; $i++) {
                my @record = $self->get_row($i);
                for (my $j=0; $j <= $self->{internal}{width}; $j++) {
			$record[$j] = qq["$record[$j]"];
                        $record[$j] =~ s/\[.*\]//;
                }
                my $record = join(',', @record);
                push (@data, $record);
        }
                                                                                                                             
                                                                                                                             
        my $data = join("\r\n", @data);
        return $data;
}

=pod

=head2 @labels = get_labels()

Get a list containing the dataset's field names.

=cut

sub get_labels {
	my $self = shift;
	my @data;

	for (my $i=0; $i <= $self->{internal}{width}; $i++) {
		push (@data, $self->{fields}->[$i]->{label});
	}

	return @data;
}

=pod

=head2 clean_times($col)

Strip times from a datetime column.

=cut

sub clean_times {
	my $self = shift;
	my $col = shift || '0';

	for (my $i=0; $i < $self->{internal}{height}; $i++) {
		$self->{data}->[$i][$col] =~ s/\s+\d\d:\d\d:\d\d.*$//;
	}
}

=pod

=head2 short_dates($col)

Convert a datetime column to use short dates.  (Note, use clean_times() first)

=cut

sub short_dates {
	my $self = shift;
	my $col = shift || '0';

	for (my $i=0; $i < $self->{internal}{height}; $i++) {
		$self->{data}->[$i][$col] =~ s/\d\d(\d\d)-(\d\d)-(\d\d)/$2-$3-$1/;
	}
}

##########################################################################################################################
# Private Methods
sub _get_labels {
	my $self = shift;
	my $table = shift;
	my $tmp;
	my $query;
	my @labels = ();

	if ($self->{connection}{type} eq 'mysql') {
		$query = "SHOW COLUMNS FROM $table";	# cant use ? placeholder (embeds in single quotes)
		$self->{connection}{sth} = $self->{connection}{dbh}->prepare($query) || confess($self->{connection}{dbh}->errstr);
		$self->{connection}{sth}->execute() || confess($self->{connection}{sth}->errstr);
	} elsif ($self->{connection}{type} eq 'odbc') {
		$query = 'SELECT column_name, data_type FROM information_schema.columns WHERE table_name=?';
		$self->{connection}{sth} = $self->{connection}{dbh}->prepare($query) || confess($self->{connection}{dbh}->errstr);
		$self->{connection}{sth}->execute($table) || confess($self->{connection}{sth}->errstr);
	} elsif ($self->{connection}{type} eq 'sqlite') {
		$query = "PRAGMA table_info($table)";
		$self->{connection}{sth} = $self->{connection}{dbh}->prepare($query) || confess($self->{connection}{dbh}->errstr);
		$self->{connection}{sth}->execute() || confess($self->{connection}{sth}->errstr);
	}

	$tmp = $self->{connection}{sth}->fetchall_arrayref();

	if (defined($tmp)) {
		my $num_rows = $#{$tmp};
		my $column = 0;

		for my $row (0..$num_rows) {
			if ($self->{connection}{type} ne 'sqlite') {
				my $name = $tmp->[$row][0];
				my $type = $tmp->[$row][1];
				$self->{fields}[$column]{label} = $name;
				$self->{fields}[$column]{name} = $name;
				$self->{fields}[$column]{type} = $type;
				$column++;
			} else {
				my $name = $tmp->[$row][1];
				my $type = $tmp->[$row][3];
				$self->{fields}[$column]{label} = $name;
				$self->{fields}[$column]{name} = $name;
				$self->{fields}[$column]{type} = $type;
				$column++;
			}
		}
	}
}

sub _extract_table {
	my $self = shift;
	my $statement = shift;
	my $table;

	# Add a space so that the regex below does not fail on statements like:
	# "SELECT * FROM some_table"

	$statement .= ' ';

	if ($statement =~ /^SELECT\s+(.*)\s+FROM\s+(\w+)\s+(.*)/) {
		$table = $2;
	} else {
		$table = 'undefined_tablename';
	}

	return $table;
}

=pod

=head1 Author

Scott Elcomb <psema4@gmail.com>

=head1 See Also

SAL, SAL::WebDDR, SAL::Graph, SAL::WebApplication

=cut

1;
