use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Point;
# ABSTRACT: Represents a Neo4j spatial point value
$Neo4j::Driver::Type::Point::VERSION = '0.14';

# may not be supported by Bolt

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Point - Represents a Neo4j spatial point value

=head1 VERSION

version 0.14

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

L<Neo4j::Driver>,
L<Neo4j Java Driver|https://neo4j.com/docs/api/java-driver/current/org/neo4j/driver/v1/types/Point.html>,
L<Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/spatial/>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2019 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
