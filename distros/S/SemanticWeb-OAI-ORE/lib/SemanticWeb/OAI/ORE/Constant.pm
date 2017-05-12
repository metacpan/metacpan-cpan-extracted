package SemanticWeb::OAI::ORE::Constant;

use warnings;
use strict;
use Carp;

=head1 NAME

SemanticWeb::OAI::ORE::Constant - Module providing constants used by OAI-ORE 
Resource Map objects

=cut

use constant ORE_PREFIX    => 'ore';
use constant ORE_NS        => 'http://www.openarchives.org/ore/terms/';
use constant DC_PREFIX     => 'dc';
use constant DC_NS         => 'http://purl.org/dc/elements/1.1/';
use constant DCT_PREFIX    => 'dcterms';
use constant DCT_NS        => 'http://purl.org/dc/terms/';
use constant RDF_PREFIX    => 'rdf';
use constant RDF_NS        => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#';
use constant FOAF_PREFIX   => 'foaf';
use constant FOAF_NS       => 'http://xmlns.com/foaf/0.1/';
use constant OWL_PREFIX    => 'owl';
use constant OWL_NS        => 'http://www.w3.org/2002/07/owl#';

use constant RESOURCE_MAP  => 'http://www.openarchives.org/ore/terms/ResourceMap';
use constant AGGREGATION   => 'http://www.openarchives.org/ore/terms/Aggregation';
use constant DESCRIBES     => 'http://www.openarchives.org/ore/terms/describes';
use constant AGGREGATES    => 'http://www.openarchives.org/ore/terms/aggregates';
use constant AGGREGATED_BY => 'http://www.openarchives.org/ore/terms/isAggregatedBy';
use constant HAS_TYPE      => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
use constant CREATOR       => 'http://purl.org/dc/terms/creator';
use constant MODIFIED      => 'http://purl.org/dc/terms/modified';
use constant RIGHTS        => 'http://purl.org/dc/elements/1.1/rights';
use constant CREATED       => 'http://purl.org/dc/terms/created';
use constant FOAF_NAME     => 'http://xmlns.com/foaf/0.1/name';
use constant FOAF_MBOX     => 'http://xmlns.com/foaf/0.1/mbox';

use constant RESOURCE      => 1;
use constant LITERAL       => 2;

use constant QUIET         => 1;
use constant WARN          => 2;
use constant FATAL         => 3;
use constant RECKLESS      => 99;
use constant ERROR_LEVEL   => [ 'NO_ERROR', 'QUIET', 'WARN', 'FATAL' ]; #order must match, not values not constant

=head2 EXPORTED CONSTANTS

The following constants may be imported either individually or using
the tags show:

 ORE_PREFIX DC_PREFIX DCT_PREFIX RDF_PREFIX (tag: prefix)
 ORE_NS DC_NS DCT_NS RDF_NS (tag: ns)
 RESOURCE_MAP AGGREGATION (tag: entity)
 DESCRIBES AGGREGATES AGGREGATED_BY HAS_TYPE CREATOR CREATED RIGHTS MODIFIED (tag: rel)
 RESOURCE LITERAL (tag: internal)
 QUIET WARN FATAL RECKLESS ERROR_LEVEL (tag: err)

for example, to use MODIFIED and other relationships one might want 
to import as:

  use SemanticWeb::OAI::ORE::Constant qw(:rel);
  print "The uri for modified time is ".MODIFIED."\n";

=cut

use base qw(Exporter);
our @EXPORT_OK = qw(
 ORE_PREFIX DC_PREFIX DCT_PREFIX RDF_PREFIX FOAF_PREFIX OWL_PREFIX 
 ORE_NS DC_NS DCT_NS RDF_NS FOAF_NS OWL_NS
 RESOURCE_MAP AGGREGATION
 DESCRIBES AGGREGATES AGGREGATED_BY HAS_TYPE CREATOR CREATED RIGHTS MODIFIED FOAF_NAME FOAF_MBOX
 RESOURCE LITERAL
 QUIET WARN FATAL RECKLESS ERROR_LEVEL
 namespace_and_name expand_qname
		    );
our %EXPORT_TAGS = (
 'prefix' => [qw( ORE_PREFIX DC_PREFIX DCT_PREFIX RDF_PREFIX FOAF_PREFIX OWL_PREFIX )],
 'ns' => [qw( ORE_NS DC_NS DCT_NS RDF_NS FOAF_NS OWL_NS )],
 'entity' => [qw( RESOURCE_MAP AGGREGATION )],
 'rel' => [qw( DESCRIBES AGGREGATES AGGREGATED_BY HAS_TYPE CREATOR CREATED RIGHTS MODIFIED FOAF_NAME FOAF_MBOX)],
 'internal' => [qw( RESOURCE LITERAL )],
 'err' => [qw( QUIET WARN FATAL RECKLESS ERROR_LEVEL )],
		    );

# Add all tag (easy since tags above are non-overlapping)
$EXPORT_TAGS{all}=[];
push @{$EXPORT_TAGS{all}}, @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS; 
push @{$EXPORT_TAGS{all}}, 'namespace_and_name', 'expand_qname';

our %PREFIX_TO_NS = ( #parens needed to avoid perl quoting strings
  ORE_PREFIX()=>ORE_NS, DC_PREFIX()=>DC_NS, DCT_PREFIX()=>DCT_NS,
  RDF_PREFIX()=>RDF_NS, FOAF_PREFIX()=>FOAF_NS, OWL_PREFIX()=>OWL_NS );

our %NS_TO_PREFIX = ( reverse %PREFIX_TO_NS );


=head2 EXPORTED SUBROUTINES

=head3 namespace_and_name($element)

FIXME - should probably change all the constants here to use 
"Clarkian" notation for namespace and element name {ns}name.

=cut

sub namespace_and_name {
  my ($element)=@_;
  foreach my $ns (ORE_NS,DC_NS,DCT_NS,RDF_NS,FOAF_NS,OWL_NS) {
    if ($element=~/^$ns(.+)$/) {
      return($ns,$1);
    }
  }
  carp "Failed to find ns for $element";
  return('',$element);
}


=head3 expand_qname

Will attempt to expand an input resource matching the qname syntax ([a-z]+:\w+)
to a full URI if the prefix is known. Otherwise string left unchanged. It should
be safe the call this expansion on something that it either a qname or a URI
because a URI will not match the pattern AND the prefixes defined here do
not correspond to URI schemes.

See also L<http://www.w3.org/TR/REC-xml-names/#NT-QName>

=cut

sub expand_qname {
  my ($qname)=@_;
  if ($qname=~/^([a-z]+):(\w+)$/) {
    if (my $ns=$PREFIX_TO_NS{$1}) {
      $qname="$ns$2";
    }
  }
  return($qname);
}

=head1 COPYRIGHT & LICENSE

Copyright 2007-2010 Simeon Warner.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

