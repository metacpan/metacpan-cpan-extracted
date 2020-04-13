use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Point;
# ABSTRACT: Represents a Neo4j spatial point value
$Neo4j::Driver::Type::Point::VERSION = '0.16';

# may not be supported by Bolt

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Point - Represents a Neo4j spatial point value

=head1 VERSION

version 0.16

=head1 DESCRIPTION

Represents a spatial point value in Neo4j.

Spatial types are only supported in Neo4j version 3.4 and above.

=head1 BUGS

L<Neo4j::Driver::Type::Point> is not yet implemented.

Spatial types may not work over a Bolt connection, because they
are not yet supported by C<libneo4j-client>
(L<#36|https://github.com/cleishm/libneo4j-client/issues/36>),
which L<Neo4j::Bolt> depends on internally. Use HTTP instead.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * Equivalent documentation for the official Neo4j drivers:
L<Point (Java)|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/types/Point.html>

=item * L<"Spatial values" in Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/temporal/>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2020 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
