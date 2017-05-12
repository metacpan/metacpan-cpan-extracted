package RDBAL::Layer::ODBC;

require 5.000;

$VERSION = "1.00";
sub Version { $VERSION; }

use Win32::ODBC;
use strict;
use vars qw(@ISA @EXPORT $VERSION $DefaultClass $AutoloadClass);
use Exporter;

@ISA = qw();

@EXPORT = ();

sub import {
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export 'RDBAL::Layer::ODBC', $callpkg, @_;
}

# Default class for the SQL object to use when all else fails.
$DefaultClass = 'RDBAL::Layer::ODBC' unless defined $RDBAL::Layer::ODBC::DefaultClass;
# This is where to look for autoloaded routines.
$AutoloadClass = $DefaultClass unless defined $RDBAL::Layer::ODBC::AutoloadClass;


sub new {
    my($class) = shift;
    my($username) = shift;
    my($password) = shift;
    my($server) = shift;
    my($self) = {};
    my($connection);
    my(%ret_dsn);

    bless $self,ref $class || $class || $DefaultClass;
    $connection =
	new Win32::ODBC("dsn=$server;UID=$username;PWD=$password");
    $self->{'connection'} = $connection;
    %ret_dsn = $connection->GetDSN();
    if ($ret_dsn{'Driver'} =~ /SQORA/) {
	$self->{'ignore_usedatabase'} = 1;
    }
    return $self;
}

#
# Execute SQL command
#
sub Sql {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($command) = shift;

    return !(Win32::ODBC::Sql($connection,$command));
}


sub RowCount {
    my($self) = shift;
    my($connection) = $self->{'connection'};

    return $connection->RowCount();
}

sub UseDatabase {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($database) = shift;
    my($retval);

    if ($self->{'ignore_usedatabase'}) {
	$retval = 0;
    } else {
	$retval = Win32::ODBC::Sql($connection,"use $database");
	while(Win32::ODBC::MoreResults($connection)) {};
    }
    return !$retval;
}

sub NextRow {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my(@row);

    if (Win32::ODBC::FetchRow($connection)) {
	@row = Win32::ODBC::Data($connection);
	return @row;
    }
    return;
}

sub Regular_Row {
    my($self) = shift;
    return 1;
}

sub More_Results {
    my($self) = shift;
    my($connection) = $self->{'connection'};

    Win32::ODBC::MoreResults($connection);
}

sub ColumnNames {
    my($self) = shift;
    my($connection) = $self->{'connection'};

    return Win32::ODBC::FieldNames($connection);
}

#
# Get column types
#
 
#
# Get column field lengths
#
 

#
# Output one result table as text
#
sub PrintTable {
    my($self) = shift;
    my(@columnname);
    my(@row);
 
    @columnname = $self->ColumnNames();
    print join("\t", @columnname)."\n";

    while(@row = $self->NextRow()) {
    	print join("\t", @row)."\n";
    }
    return 1;
}

#
# Output one or more result tables as text
#
sub PrintTables {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my(@columnname);
    my(@row);
 
    do {
	PrintTable($self);
    } while ($self->More_Results());
    return 1;
}

#
# Execute an SQL query and return the results in an array
#
# If the query produces a single value per row, just return
# an array of the data.
#
# If the query produces multiple values per row, return an
# array of references to arrays.
#
sub Query {
    my($self) = shift;
    my($command) = shift;
    my(@out,@row,$ptr,$ret);

    $ret = $self->Sql($command);
    if (!$ret) {
	print "Error on query $command\n";
	return undef;
    }

    do { 
    	while(@row = $self->NextRow()) {
	    if (@row<=1) { 
		push(@out,@row[0]); 
	    } else { 
		$ptr = [];
		push(@{$ptr},@row);
		push(@out,$ptr);
	    }
	}
    } while ($self->More_Results());
    return(@out); 
}


1;
