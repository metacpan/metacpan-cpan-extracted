package RDBAL::Layer::SybaseDBlib;

require 5.000;

$VERSION = "1.00";
sub Version { $VERSION; }

use Sybase::DBlib;
use strict;
use vars qw(@ISA @EXPORT $VERSION $DefaultClass $AutoloadClass);
use Exporter;

@ISA = qw();

@EXPORT = ();

sub import {
    my $pkg = shift;
    my $callpkg = caller;
    Exporter::export 'RDBAL::Layer::SybaseDBlib', $callpkg, @_;
}

# Default class for the SQL object to use when all else fails.
$DefaultClass = 'RDBAL::Layer::SybaseDBlib' unless defined $RDBAL::Layer::SybaseDBlib::DefaultClass;
# This is where to look for autoloaded routines.
$AutoloadClass = $DefaultClass unless defined $RDBAL::Layer::SybaseDBlib::AutoloadClass;


sub new {
    my($class) = shift;
    my($username) = shift;
    my($password) = shift;
    my($server) = shift;
    my($self) = {};

    bless $self,ref $class || $class || $DefaultClass;
    $self->{'connection'} =
      Sybase::DBlib->dblogin($username, $password, $server);
    return $self;
}

#
# Execute SQL command
#
sub Sql {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($command) = shift;
 
    (Sybase::DBlib::dbcmd($connection,$command) == &Sybase::DBlib::SUCCEED)
        or return undef;
 
    (Sybase::DBlib::dbsqlexec($connection) == &Sybase::DBlib::SUCCEED)
        or return undef;
 
    (Sybase::DBlib::dbresults($connection) == &Sybase::DBlib::SUCCEED)
        or return undef;
    return 1;
}

sub RowCount {
    my($self) = shift;
    my($connection) = $self->{'connection'};

    return $connection->DBCOUNT;
}

sub UseDatabase {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($database) = shift;
    my($retval);

    return Sybase::DBlib::dbuse($connection,$database);
}

#
#   @row = NextRow($connection);
#

sub NextRow {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my(@row) = Sybase::DBlib::dbnextrow($connection);
    return @row;
}

#
# $bool_regular_row = Regular_Row($connection);
#

sub Regular_Row {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    return ($connection->{DBstatus} == &Sybase::DBlib::REG_ROW);
}

#
# $bool_no_more_result_sets = More_Results($connection);
#
sub More_Results {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    return (Sybase::DBlib::dbresults($connection) != &Sybase::DBlib::NO_MORE_RESULTS);
}

#
# Get column names
#
 
sub ColumnNames {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($cols);
    my($i);
    my(@retval);
 
    $cols = Sybase::DBlib::dbnumcols($connection);
    for ($i = 1; $i <= $cols; $i++) {
        push @retval, (Sybase::DBlib::dbcolname($connection,$i));
    }
    return @retval;
}
 
#
# Get column types
#
 
sub ColumnTypes {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($cols);
    my($i);
    my(@retval);
 
    $cols = Sybase::DBlib::dbnumcols($connection);
    for ($i = 1; $i <= $cols; $i++) {
        push @retval, (Sybase::DBlib::dbcoltype($connection,$i));
    }
    return @retval;
}
 
#
# Get column field lengths
#
 
sub ColumnLengths {
    my($self) = shift;
    my($connection) = $self->{'connection'};
    my($cols);
    my($i);
    my(@retval);
 
    $cols = Sybase::DBlib::dbnumcols($connection);
    for ($i = 1; $i <= $cols; $i++) {
        push @retval, (Sybase::DBlib::dbcollen($connection,$i));
    }
    return @retval;
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
