package RDF::NS::Curated;

use 5.006000;
use strict;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.005';

sub new {
  my $class = shift;
  my %prefix_ns = (
						 adms => 'http://www.w3.org/ns/adms#',
						 as => 'https://www.w3.org/ns/activitystreams#',
						 bibo => 'http://purl.org/ontology/bibo/',
						 cc => 'http://creativecommons.org/ns#',
						 ctag => 'http://commontag.org/ns#',
						 dbo => 'http://dbpedia.org/ontology/',
						 dbp => 'http://dbpedia.org/property/',
						 dc => 'http://purl.org/dc/terms/',
						 dc11 => 'http://purl.org/dc/elements/1.1/ => ',
						 dcat => 'http://www.w3.org/ns/dcat#',
						 dctype => 'http://purl.org/dc/dcmitype/',
						 doap => 'http://usefulinc.com/ns/doap#',
						 dqv => 'http://www.w3.org/ns/dqv#',
						 duv => 'http://www.w3.org/ns/duv#',
						 earl => 'http://www.w3.org/ns/earl#',
						 event => 'http://purl.org/NET/c4dm/event.owl#',
						 foaf => 'http://xmlns.com/foaf/0.1/',
						 frbr => 'http://purl.org/vocab/frbr/core#',
						 gn => 'http://www.geonames.org/ontology#',
						 gr => 'http://purl.org/goodrelations/v1#',
						 grddl => 'http://www.w3.org/2003/g/data-view#',
						 hydra => 'http://www.w3.org/ns/hydra/core#',
						 ical => 'http://www.w3.org/2002/12/cal/icaltzd#',
						 ldp => 'http://www.w3.org/ns/ldp#',
						 ma => 'http://www.w3.org/ns/ma-ont#',
						 oa => 'http://www.w3.org/ns/oa#',
						 odrl => 'http://www.w3.org/ns/odrl/2/',
						 og => 'http://ogp.me/ns#',
						 org => 'http://www.w3.org/ns/org#',
						 owl => 'http://www.w3.org/2002/07/owl#',
						 pos => 'http://www.w3.org/2003/01/geo/wgs84_pos#',
						 prov => 'http://www.w3.org/ns/prov#',
						 qb => 'http://purl.org/linked-data/cube#',
						 rel => 'http://purl.org/vocab/relationship/',
						 rev => 'http://purl.org/stuff/rev#',
						 rif => 'http://www.w3.org/2007/rif#',
						 rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
						 rdfa => 'http://www.w3.org/ns/rdfa#',
						 rdfs => 'http://www.w3.org/2000/01/rdf-schema#',
						 rr => 'http://www.w3.org/ns/r2rml#',
						 schema => 'http://schema.org/',
						 sd => 'http://www.w3.org/ns/sparql-service-description#',
						 sioc => 'http://rdfs.org/sioc/ns#',
						 skos => 'http://www.w3.org/2004/02/skos/core#',
						 skosxl => 'http://www.w3.org/2008/05/skos-xl#',
						 ssn => 'http://www.w3.org/ns/ssn/',
						 time => 'http://www.w3.org/2006/time#',
						 v => 'http://rdf.data-vocabulary.org/#',
						 vann => 'http://purl.org/vocab/vann/',
						 vcard => 'http://www.w3.org/2006/vcard/ns#',
						 void => 'http://rdfs.org/ns/void#',
						 vs => 'http://www.w3.org/2003/06/sw-vocab-status/ns#',
						 wdr => 'http://www.w3.org/2007/05/powder#',
						 wdrs => 'http://www.w3.org/2007/05/powder-s#',
						 xhv => 'http://www.w3.org/1999/xhtml/vocab#',
						 xml => 'http://www.w3.org/XML/1998/namespace',
						 xsd => 'http://www.w3.org/2001/XMLSchema#',
						 yago => 'http://yago-knowledge.org/resource/',
						);

  my $self = {
				  prefix_namespace => \%prefix_ns
				 };
  return bless($self, $class);
}

sub uri {
  my $self = shift;
  my $prefix = shift;
  return $self->{prefix_namespace}->{$prefix};
}

sub prefix {
  my $self = shift;
  my $namespace = shift;
  my $ns_prefix = $self->{namespace_prefix};
  unless ($ns_prefix) {
	 $ns_prefix = {reverse %{$self->{prefix_namespace}}};
	 $self->{namespace_prefix} = $ns_prefix;
  }
  return $ns_prefix->{$namespace};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

RDF::NS::Curated - A curated set of RDF prefixes

=head1 SYNOPSIS

  my $ns = RDF::NS::Curated->new;
  print $ns->uri('foaf'); # prints http://xmlns.com/foaf/0.1/
  print $ns->prefix('http://schema.org/'); # prints schema

=head1 DESCRIPTION

This contains a list of 58 prefix and URI pairs that are commonly used
in RDF. The intention is that prefixes in this list can be safely used
in code that has a long lifetime. The list has been derived mostly
from W3C standards documents, but also some popularity lists. See the
source code of this package for the full list.

It is intended to be used with e.g. L<URI::NamespaceMap>.

=head2 Methods

=over

=item C<< new >>

Constructor. Takes no arguments.

=item C<< uri($prefix) >>

This will return the URI (as a plain string) of the supplied prefix or C<undef> if it is not registered.

=item C<< prefix($uri) >>

This will return the prefix corresponding to the supplied URI string or C<undef> if it is not registered.

=back

=head1 BUGS

Please report any bugs to
L<https://github.com/kjetilk/p5-rdf-ns-curated/issues>.

=head1 SEE ALSO

L<RDF::NS>, L<XML::CommonNS>, L<RDF::Prefixes>.

=head1 AUTHOR

Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2015, 2017 by Kjetil Kjernsmo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

