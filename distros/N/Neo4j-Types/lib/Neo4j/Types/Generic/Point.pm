use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::Generic::Point;
# ABSTRACT: Generic representation of a Neo4j spatial point value
$Neo4j::Types::Generic::Point::VERSION = '2.00';

use parent 'Neo4j::Types::Point';

use Carp qw(croak);


my %DIM = ( 4326 => 2, 4979 => 3, 7203 => 2, 9157 => 3 );

sub new {
	# uncoverable pod - see Generic.pod
	my ($class, $srid, @coordinates) = @_;
	
	croak "Points must have SRID" unless defined $srid;
	my $dim = $DIM{$srid};
	croak "Unsupported SRID $srid" unless defined $dim;
	croak "Points with SRID $srid must have $dim dimensions" if @coordinates < $dim;
	return bless [ $srid, @coordinates[0 .. $dim - 1] ], __PACKAGE__;
}


sub X {
	# uncoverable pod - see Generic.pod
	return shift->[1];
}


sub longitude {
	# uncoverable pod - see Generic.pod
	return shift->[1];
}


sub Y {
	# uncoverable pod - see Generic.pod
	return shift->[2];
}


sub latitude {
	# uncoverable pod - see Generic.pod
	return shift->[2];
}


sub Z {
	# uncoverable pod - see Generic.pod
	return shift->[3];
}


sub height {
	# uncoverable pod - see Generic.pod
	return shift->[3];
}


sub srid {
	return shift->[0];
}


sub coordinates {
	my @coordinates = @{$_[0]}[ 1 .. $#{$_[0]} ];
	return @coordinates;
}


1;
