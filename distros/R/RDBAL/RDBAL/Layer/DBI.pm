package RDBAL::Layer::DBI;

require 5.000;

$VERSION = "1.00";
sub Version { $VERSION; }

use strict;
use vars qw(@ISA @EXPORT $VERSION $DefaultClass $AutoloadClass);
use Exporter;

@ISA = qw();

@EXPORT = ();

sub import {
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export 'RDBAL::Layer::DBI', $callpkg, @_;
}

# Default class for the SQL object to use when all else fails.
$DefaultClass = 'RDBAL::Layer::DBI' unless defined $RDBAL::Layer::DBI::DefaultClass;
# This is where to look for autoloaded routines.
$AutoloadClass = $DefaultClass unless defined $RDBAL::Layer::DBI::AutoloadClass;


sub new {
    my($class) = shift;
    my($username) = shift;
    my($password) = shift;
    my($server) = shift;
    my($driver) = shift;
    my($database) = shift;
    my($self) = {};
    my($data_source);

    bless $self,ref $class || $class || $DefaultClass;
    if ($driver eq 'Sybase') {
	$data_source = "dbi:$driver" . ':server=' . $server;
    } else {
	if (defined($database)) {
	    $data_source = "dbi:$driver:$database";
	} else {
	    $data_source = "dbi:$driver:";
	}
    }
    $self->{'connection'} =
	DBI->connect($data_source, $username, $password, { PrintError => 0 });
    $self->{'driver'} = $driver;
    return $self;
}

#
# Execute SQL command
#
sub Sql {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($command) = shift;
    my($sth);
 
    if (defined($self->{'sth'})) {
	$self->{'sth'}->finish;
    }
    $sth = $connection->prepare($command) or return undef;
    $self->{'sth'} = $sth;
    $self->{'sth'}->execute or return undef;
    $self->{'empty_fetch'} = 0;
    return 1;
}

sub RowCount {
    my($self) = shift;

    return $self->{'sth'}->rows;
}

sub UseDatabase {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($database) = shift;
    my($retval);

    if ($self->{'driver'} eq 'Sybase' ) {
	$self->Sql("use $database") or return undef;
	while($self->More_Results) {};
    }
    return 1;
}

#
#   @row = NextRow($connection);
#

sub NextRow {
    my($self) = shift;
    my(@row) = $self->{'sth'}->fetchrow_array;
    $self->{'empty_fetch'} = 0;
    return @row;
}

#
# $bool_regular_row = Regular_Row($connection);
#

sub Regular_Row {
    my($self) = shift;

    if ($self->{'sth'}->{NAME}->[0] ne 'COL(1)') {
	return 1;
    } else {
	return 0;
    }
}

#
# $bool_no_more_result_sets = More_Results($connection);
#
sub More_Results {
    my($self) = shift;
    my($retval) = 0;
    my(@row);

    if ($self->{'empty_fetch'}) {
	while($self->{'sth'}->fetchrow_array) {}
    }
    $self->{'empty_fetch'} = 1;
    if (defined($self->{'sth'}->{syb_more_results}) &&
	$self->{'sth'}->{syb_more_results}) {
	$retval = 1;
    }
    return $retval;
}

#
# Get column names
#
 
sub ColumnNames {
    my($self) = shift;
 
    return @{$self->{'sth'}->{NAME}};
}
 
#
# Get column types
#
 
sub ColumnTypes {
    my($self) = shift;
    return undef;
}
 
#
# Get column field lengths
#
 
sub ColumnLengths {
    my($self) = shift;
    return undef;
}

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
		push(@out,$row[0]); 
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

__END__
