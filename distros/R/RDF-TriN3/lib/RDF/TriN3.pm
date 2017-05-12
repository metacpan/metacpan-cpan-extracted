package RDF::TriN3;

use 5.010;
use RDF::Trine;
use RDF::Trine::Node::Formula;
use RDF::Trine::Parser::Notation3;
use RDF::Trine::Parser::ShorthandRDF;
use RDF::Trine::Serializer::Notation3;

our $VERSION = '0.206';

1;

__END__

=head1 NAME

RDF::TriN3 - notation 3 extensions for RDF::Trine

=head1 DESCRIPTION

This module extends L<RDF::Trine> in three ways:

=over 4

=item * Adds a Notation 3 parser.

=item * Adds a Notation 3 serializer.

=item * Provides a subclass of literals to represent Notation 3 formulae.

=back

In addition, a parser is provided for Notation 3 extended with ShorthandRDF
notation - L<http://esw.w3.org/ShorthandRDF>.

=head1 BUGS AND LIMITATIONS

Implementing N3 logic and the cwm built-ins is considered outside the scope
of this distribution, though I am interested in doing that as part of a
separate project.

RDF::TriN3 currently relies entirely on RDF::Trine to provide implementations
of the concept of graphs, and storage. Thus any graphs that can't be
represented using RDF::Trine can't be represented in RDF::TriN3. RDF::Trine's
graph model is a superset of RDF, but a subset of Notation 3's model. While
this allows literal subjects, and literal and blank node predicates, these
may not be supported by all storage engines; additionally top-level variables
(?foo), and top-level @forSome and @forAll (i.e. not nested inside a formula)
might cause problems.

RDF::Trine::Store::DBI has some issues with literal subjects, and literal and
blank node predicates, allowing them to be stored, but not retrieved. From
version 0.128, RDF::Trine::Store::DBI offers a C<clear_restrictions> method
that should resolve these issues. RDF::Trine::Store::Memory is fine. Other
stores are not tested.

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<RDF::Trine::Node::Formula>,
L<RDF::Trine::Parser::Notation3>,
L<RDF::Trine::Serializer::Notation3>.

L<RDF::Trine::Parser::ShorthandRDF>,
L<RDF::Trine::Parser::Pretdsl>.

L<RDF::Trine>.

L<http://www.perlrdf.org/>.

L<http://www.w3.org/DesignIssues/Notation3>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

Copyright 2010-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut
