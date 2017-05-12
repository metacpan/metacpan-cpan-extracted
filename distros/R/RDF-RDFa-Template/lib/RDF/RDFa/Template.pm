package RDF::RDFa::Template;

use warnings;
use strict;

our $VERSION = '0.05';


=head1 NAME

RDF::RDFa::Template - A simple templating system using RDFa to build RDF data views

=head1 VERSION

Version 0.05

=head1 DESCRIPTION

=head1 SYNOPSIS

This module takes an RDFa Template document, and parses it. Then it
builds something that you can use to run queries.



=head1 METHODS

This package is just a placeholder for now, other packages in this
distribution contains the actual code. See the below TODO for the
status of this module, though.

=head1 TODO

This is an initial release just to enable a meaningful
discussion. Thus, there are many remaining tasks before this is a
fully functional templating system. This lists some of the most severe
things that need to be addressed:

=over

=item * Support for queries with multiple solutions is essential, but
not yet implemented.

=item * Multiple queries in a single template is not tested.

=item * Prefixes are hardcoded. In the finished system, the XML
namespace prefixes must not be hardcoded, but namespace URIs must be
used instead. This is not there yet. Thus, you need to use C<rat> and
C<sub> like in the examples.

=item * The attribute that sets the graph name is hardcoded to
C<g:graph> or C<{http://example.org/graph#}graph>. This will be up to
the author to select and pass as C<doc_graph> for each unit. Thus,
this must change.

=item * The RDF objects are checked for variables, which is contained
in XML Literals. Only the first child is used, this may not be
reliable.

=item * DTD information is not prefixed to the result document.

=item * The system doesn't follow OOP best practices in many places,
as instance variables are accessed directly rather than using
methods. Pretty nasty, it is, but it will be corrected.

=item * Consider using just one namespace.

=back

=head1 EXAMPLE SCRIPT

There is a simple web server script in the C<examples/> directory of
this distribution. This sets up a web server on your machine that can
do the template transform. Any template files in the directory can be
visited with a browser, e.g.

  http://localhost:8080/dbpedia-mustang-range.input.xhtml



=head1 AUTHOR

Kjetil Kjernsmo, C<< <kjetilk at cpan.org> >>

=head1 BUGS

Please report any bugs not already on the TODO list to C<bug-rdf-rdfa-template
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=RDF-RDFa-Template>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RDF::RDFa::Template

To discuss further directions for this module, please use the Perl/RDF mailing list at
L<http://lists.perlrdf.org/listinfo/dev>.



You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=RDF-RDFa-Template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/RDF-RDFa-Template>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/RDF-RDFa-Template>

=item * Search CPAN

L<http://search.cpan.org/dist/RDF-RDFa-Template/>

=back


=head1 ACKNOWLEDGEMENTS

I would like to thank Greg Williams and Toby Inkster for useful
discussions when creating this module. I have also received important
help from Kip Hampton and Chris Prather.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Kjetil Kjernsmo.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of RDF::RDFa::Template
