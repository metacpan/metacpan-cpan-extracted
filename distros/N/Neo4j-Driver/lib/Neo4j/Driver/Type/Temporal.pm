use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Temporal;
# ABSTRACT: Represents a Neo4j temporal value
$Neo4j::Driver::Type::Temporal::VERSION = '0.14';

# may not be supported by Bolt

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Temporal - Represents a Neo4j temporal value

=head1 VERSION

version 0.14

=head1 DESCRIPTION

Represents a date, time or duration value in Neo4j.

Temporal types are only supported in Neo4j version 3.4 and above.

=head1 BUGS

L<Neo4j::Driver::Type::Temporal> is not yet implemented.

The package name C<Neo4j::Driver::Type::Temporal> may change in future.

Temporal types may not work over a Bolt connection, because they
are not yet supported by C<libneo4j-client>
(L<#36|https://github.com/cleishm/libneo4j-client/issues/36>),
which L<Neo4j::Bolt> depends on internally. Use HTTP instead.

=head1 SEE ALSO

L<Neo4j::Driver>,
L<Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/temporal/>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2019 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
