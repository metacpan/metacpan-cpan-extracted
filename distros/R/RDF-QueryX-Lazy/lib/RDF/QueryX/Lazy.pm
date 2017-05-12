package RDF::QueryX::Lazy;

use 5.010;
use common::sense;
use constant { FALSE => 0, TRUE => 1 };
use utf8;

our (%Lazy);
BEGIN {
	$RDF::QueryX::Lazy::AUTHORITY = 'cpan:TOBYINK';
	$RDF::QueryX::Lazy::VERSION   = '0.003';

	%Lazy = 
		map { /^PREFIX (.+?):/ ? ($1 => $_) : () }
		split /\r?\n/, <<'LAZY';
PREFIX bibo:  <http://purl.org/ontology/bibo/>
PREFIX bio:   <http://purl.org/vocab/bio/0.1/>
PREFIX cc:    <http://creativecommons.org/ns#>
PREFIX dc:    <http://purl.org/dc/elements/1.1/>
PREFIX doap:  <http://usefulinc.com/ns/doap#>
PREFIX foaf:  <http://xmlns.com/foaf/0.1/>
PREFIX frbr:  <http://purl.org/vocab/frbr/core#>
PREFIX geo:   <http://www.w3.org/2003/01/geo/wgs84_pos#>
PREFIX gr:    <http://purl.org/goodrelations/v1#>
PREFIX ical:  <http://www.w3.org/2002/12/cal/ical#>
PREFIX og:    <http://ogp.me/ns#>
PREFIX org:   <http://www.w3.org/ns/org#>
PREFIX owl:   <http://www.w3.org/2002/07/owl#>
PREFIX rdf:   <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfa:  <http://www.w3.org/ns/rdfa#>
PREFIX rdfg:  <http://www.w3.org/2004/03/trix/rdfg-1/>
PREFIX rdfs:  <http://www.w3.org/2000/01/rdf-schema#>
PREFIX rev:   <http://purl.org/stuff/rev#>
PREFIX rss:   <http://purl.org/rss/1.0/>
PREFIX sioc:  <http://rdfs.org/sioc/ns#>
PREFIX skos:  <http://www.w3.org/2004/02/skos/core#>
PREFIX vann:  <http://purl.org/vocab/vann/>
PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>
PREFIX void:  <http://rdfs.org/ns/void#>
PREFIX wdrs:  <http://www.w3.org/2007/05/powder-s#>
PREFIX wot:   <http://xmlns.com/wot/0.1/>
PREFIX xhv:   <http://www.w3.org/1999/xhtml/vocab#>
PREFIX xsd:   <http://www.w3.org/2001/XMLSchema#>
LAZY
}

use Scalar::Util 0 qw[blessed refaddr];
use RDF::Query 2.900;

use parent qw[RDF::Query];

sub new
{
	my ($class, $query, @params) = @_;
	
	my $lazy = '';
	$lazy .= join "\n",
		map  { $Lazy{$_} }
		grep { $query =~ /$_:/ }
		keys %Lazy;

	if (exists $params[0]
	and ref $params[0] eq 'HASH'
	and ref $params[0]{lazy} eq 'HASH')
	{
		my %more = %{ delete($params[0]{lazy}) // {} };
		$lazy .= join "\n",
			map  { sprintf('PREFIX %s: <%s>', $_, $more{$_}) }
			grep { $query =~ /$_:/ }
			keys %more;
	}
	
	return $class->SUPER::new($lazy.$query, @params);
}

TRUE;

__END__

=head1 NAME

RDF::QueryX::Lazy - yeah, all those PREFIX definitions get boring

=head1 SYNOPSIS

 my $query = RDF::QueryX::Lazy->new(<<SPARQL);
 SELECT *
 WHERE {
   ?person foaf:name ?name .
   OPTIONAL { ?person foaf:homepage ?page . }
 }
 SPARQL

=head1 DESCRIPTION

This is a fairly trivial subclass of L<RDF::Query> that auto-defines
many prefixes for you, so you can be lazy. It should have most of the
common ones in there.

Oh yeah, and if you want, you can pass a key 'lazy' in the RDF::Query
C<< %options >> hash with additional prefix mappings.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=RDF-QueryX-Lazy>.

=head1 SEE ALSO

L<RDF::Query>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

