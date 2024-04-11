use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Point;
# ABSTRACT: Represents a Neo4j spatial point value
$Neo4j::Driver::Type::Point::VERSION = '0.48';

# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Types::Point';


sub _parse {
	my ($self) = @_;
	
	if ( ! exists $self->{'@'} ) {  # JSON format
		$self->{srid} = $self->{crs}{srid};
		return;
	}
	
	my ($srid, $x, $y, $z) = $self->{'@'} =~ m/^SRID=([0-9]+);POINT(?: Z)? ?\(([-0-9.]+) ([-0-9.]+)(?: ([-0-9.]+))?\)$/;
	
	$self->{srid} = 0 + $srid;
	my @coords = (0 + $x, 0 + $y);
	push @coords, 0 + $z if defined $z;
	$self->{coordinates} = \@coords;
}


sub srid {
	my ($self) = @_;
	exists $self->{srid} or $self->_parse;
	return $self->{srid};
}


sub coordinates {
	my ($self) = @_;
	exists $self->{coordinates} or $self->_parse;
	return @{$self->{coordinates}};
}


1;
