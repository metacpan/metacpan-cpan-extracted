use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Point;
# ABSTRACT: Represents a Neo4j spatial point value
$Neo4j::Driver::Type::Point::VERSION = '0.42';

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Point - Represents a Neo4j spatial point value

=head1 VERSION

version 0.42

=head1 DESCRIPTION

Represents a spatial point value in Neo4j.

Spatial types are only supported in Neo4j version 3.4 and above.

I<B<Note:> This module documentation will soon be replaced entirely
by L<Neo4j::Driver::Types> and L<Neo4j::Types::Point>.>

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver::Types>

=item * L<Neo4j::Types::Point>

=item * Equivalent documentation for the official Neo4j drivers:
L<Point (Java)|https://neo4j.com/docs/api/java-driver/5.2/org.neo4j.driver/org/neo4j/driver/types/Point.html>

=item * L<"Spatial values" in Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/5/syntax/spatial/>

=back

=head1 AUTHOR

Arne Johannessen (L<AJNN|https://arne.johannessen.de/>)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
