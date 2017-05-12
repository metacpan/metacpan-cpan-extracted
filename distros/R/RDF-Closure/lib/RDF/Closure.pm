package RDF::Closure;

use 5.008;
use strict;
use utf8;

use RDF::Trine::Namespace qw[RDF RDFS OWL XSD];
use RDF::Trine::Parser::OwlFn qw[];
use RDF::Closure::Engine qw[];
use RDF::Closure::Model qw[];
use Scalar::Util qw[];

eval { require RDF::Trine };
our @ISA = qw(RDF::Trine);

use constant FLT_NONRDF => 1;
use constant FLT_BORING => 2;

our $VERSION = '0.001';

our @EXPORT_OK;
BEGIN
{
	@EXPORT_OK = (@RDF::Trine::EXPORT_OK, qw[mk_filter FLT_NONRDF FLT_BORING $RDF $RDFS $OWL $XSD]);
}

sub mk_filter
{
	my ($conditions, $boring_contexts) = @_;
	
	$boring_contexts = [$boring_contexts] unless ref $boring_contexts eq 'ARRAY';
	
	return sub
	{
		my ($st) = @_;
		
		if ($conditions & FLT_NONRDF)
		{
			return 0 unless $st->rdf_compatible;
		}
		
		return 0 if grep { $st->context->equal($_) } @$boring_contexts;
		
		if ($conditions & FLT_BORING)
		{
			return 0
				if $st->subject->equal($st->object)
				&& {
					$OWL->sameAs->uri              => 1,
					$OWL->equivalentProperty->uri  => 1,
					$OWL->equivalentClass->uri     => 1,
					$RDFS->subPropertyOf->uri      => 1,
					$RDFS->subClassOf->uri         => 1,
					}->{$st->predicate->uri};
			
			my @nodes = $st->nodes;
			foreach my $node (@nodes[0..2])
			{
				return 1
					unless in_namespace($node, $RDF)
					||     in_namespace($node, $RDFS)
					||     in_namespace($node, $OWL)
					||     in_namespace($node, $XSD);
			}
			return 0;
		}
		
		return 1;
	};
}

sub in_namespace
{
	my ($node, $ns) = @_;
	
	return 0
		if Scalar::Util::blessed($node)
		&& !$node->is_resource;
	
	my $ns_str      = $ns->uri('')->uri;
	my $node_substr = substr($node->uri, 0, length $ns_str);
	
	return ($node_substr eq $ns_str);
}

1;

=head1 NAME

RDF::Closure - pure Perl RDF inferencing

=head1 SYNOPSIS

 use RDF::Trine::Iterator qw[sgrep];
 use RDF::Closure qw[iri mk_filter FLT_NONRDF FLT_BORING];
 
 my $data = iri('http://bloggs.example.com/foaf.rdf');
 my $foaf = iri('http://xmlns.com/foaf/0.1/index.rdf');
 
 my $model = RDF::Trine::Model->temporary_model;
 my $p     = 'RDF::Trine::Parser';
 $p->parse_url_into_model($data->uri, $model, context => $data->uri);
 $p->parse_url_into_model($foaf->uri, $model, context => $foaf->uri);
 
 my $cl = RDF::Closure::Engine->new('rdfs', $model);
 $cl->closure;
 
 my $filter = mk_filter(FLT_NONRDF|FLT_BORING, [$foaf]);  
 my $output = &sgrep($filter, $model->as_stream);
 
 print RDF::Trine::Serializer
   ->new('RDFXML')
   ->serialize_iterator_to_string($output);

=head1 DESCRIPTION

This distribution is a pure Perl RDF inference engine designed as an add-in
for L<RDF::Trine>. It is largely a port of Ivan Herman's Python RDFClosure
library, though there has been some restructuing, and there are a few extras
thrown in.

Where one of the Perl modules has a direct equivalent in Ivan's library,
this is noted in the POD.

=head2 Functions

This package inherits from L<RDF::Trine> and exports the same functions,
plus:

=over

=item * C<< mk_filter($basic_filters, $ignore_contexts) >>

Creates a filter (coderef) suitable for use with C<sgrep> from
L<RDF::Trine::Iterator>.

C<$basic_filters> is an integer which can be assembled by bitwise-OR-ing
the constants C<FLT_NONRDF> and C<FLT_BORING>.

C<$ignore_contexts> is an arrayref of L<RDF::Trine::Node> objects, each
of which represents a context that should be filtered out.

  use RDF::Trine::Iterator qw[sgrep];
  use RDF::Closure qw[iri mk_filter FLT_NONRDF FLT_BORING];
  
  my $foaf   = iri('http://xmlns.com/foaf/0.1/index.rdf');
  my $filter = mk_filter(FLT_NONRDF|FLT_BORING, [$foaf]);
  
  my $remaining = &sgrep($filter, $model->as_stream);
  
  # $remaining is now an iterator which will return all triples
  # from $model except: those in the FOAF named graph, those which
  # are non-RDF (e.g. literal subject) and those which are boring.

Which triples are boring? Any triple of the form { ?x owl:sameAs ?x .},
{ ?x owl:equivalentProperty ?x .}, { ?x owl:equivalentClass ?x .},
{ ?x rdfs:subPropertyOf ?x .} or { ?x rdfs:subClassOf ?x .} is boring
(i.e. where these statements have the same term in subject and object
position). Any triple where the subject, predicate and object nodes are
all in the RDF, RDFS, OWL or XSD namespaces is boring. Other triples are
not boring.

=back

For convenience, C<RDF::Closure> also exports variables called C<$RDF>,
C<$RDFS>, C<$OWL> and C<$XSD> which are L<RDF::Trine::Namespace> objects.

=head1 SEE ALSO

L<RDF::Closure::Engine>,
L<RDF::Closure::Model>,
L<RDF::Trine::Parser::OwlFn>.

L<RDF::Trine>,
L<RDF::Query>.

L<http://www.perlrdf.org/>.

L<http://www.ivan-herman.net/Misc/2008/owlrl/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright 2011-2012 Toby Inkster

This library is free software; you can redistribute it and/or modify it
under any of the following licences:

=over

=item * The Artistic License 1.0 L<http://www.perlfoundation.org/artistic_license_1_0>.

=item * The GNU General Public License Version 1 L<http://www.gnu.org/licenses/old-licenses/gpl-1.0.txt>,
or (at your option) any later version.

=item * The W3C Software Notice and License L<http://www.w3.org/Consortium/Legal/2002/copyright-software-20021231>.

=item * The Clarified Artistic License L<http://www.ncftp.com/ncftp/doc/LICENSE.txt>.

=back

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

