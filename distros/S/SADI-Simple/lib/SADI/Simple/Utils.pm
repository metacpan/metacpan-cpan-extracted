package SADI::Simple::Utils;
{
  $SADI::Simple::Utils::VERSION = '0.15';
}

use strict;
use warnings;

use File::Spec;
use RDF::Trine::Model 0.135;
use RDF::Trine::Parser 0.135;
use RDF::Trine::Serializer 0.135;
use File::Spec::Functions;

=head1 NAME

SADI::Simple::Utils - internal utils for manipulating RDF

=cut

=head1 DESCRIPTION

There are no public methods in this module.

=cut

sub rdfxml_to_n3
{
    my ($self, $rdfxml) = @_;

    $rdfxml = $self
      unless ref($self) =~ m/^SADI::Simple::Utils/ or $self =~ /^SADI::Simple::Utils/;

    my $model = RDF::Trine::Model->temporary_model;
    my $parser = RDF::Trine::Parser->new('rdfxml');

    eval { $parser->parse_into_model(undef, $rdfxml, $model) };

    die "failed to convert RDF/XML to TTL, error parsing RDF/XML: $@" if $@;
    
    my $serializer = RDF::Trine::Serializer->new('turtle');
    
    return $self->serialize_model($model, 'text/rdf+n3');
}

sub n3_to_rdfxml
{
    my ($self, $n3) = @_;

    $n3 = $self
      unless ref($self) =~ m/^SADI::Simple::Utils/ or $self =~ /^SADI::Simple::Utils/;

    my $model = RDF::Trine::Model->temporary_model;
    my $parser = RDF::Trine::Parser->new('turtle');

    eval { $parser->parse_into_model(undef, $n3, $model) };

    die "failed to convert N3 to RDF/XML, error parsing N3: $@" if $@;
    
    my $serializer = RDF::Trine::Serializer->new('rdfxml');
    
    return $self->serialize_model($model, 'text/rdf+n3');
}

my @N3_MIME_TYPES = (
    'text/rdf+n3',
    'text/n3',
    'application/x-turtle',
);

sub serialize_model
{
    my ($self, $model, $mime_type) = @_;

    unless(ref($self) =~ m/^SADI::Simple::Utils/ or $self =~ /^SADI::Simple::Utils/) {
        ($model, $mime_type) = @_;
    }

    my $serializer;

    if (grep($_ eq $mime_type, @N3_MIME_TYPES)) {
        $serializer = RDF::Trine::Serializer->new('turtle');
    } elsif (lc($mime_type) eq "application/n-quads") {
    	$serializer = RDF::Trine::Serializer::NQuads->new();
    	#$self->add_nanopub_metadata($model);
    } else {
        $serializer = RDF::Trine::Serializer->new('rdfxml');
    }
    
    return $serializer->serialize_model_to_string($model);
    
}

sub get_standard_content_type
{
    my ($self, $content_type) = @_;

    unless(ref($self) =~ m/^SADI::Simple::Utils/ or $self =~ /^SADI::Simple::Utils/) {
        ($content_type) = @_;
    }

    my $standard_content_type = 'application/rdf+xml';

    if (defined $content_type) {
        $standard_content_type = 'text/rdf+n3' if $content_type =~ m|text/rdf\+n3|gi;
        $standard_content_type = 'text/rdf+n3' if $content_type =~ m|text/n3|gi;
    }

    return $standard_content_type;
}


sub add_nanopub_metadata {
	my ($self) = @_;

#
#@prefix : <http://www.example.org/mynanopub/>.
#@prefix ex: <http://www.example.org/>.
#@prefix np: <http://www.nanopub.org/nschema#>.
#@prefix dct: <http://purl.org/dc/terms/>.
#@prefix go: <http://purl.obolibrary.org/obo/>.
#@prefix up: <http://purl.uniprot.org/core/> .
#@prefix pav: <http://swan.mindinformatics.org/ontologies/1.2/pav/>
#@prefix xsd: <http://www.w3.org/2001/XMLSchema#>.
#{
#:nanopub1 np:hasAssertion :G1;
#np:hasProvenance :G2;
#np:hasSupporting :G3.
#:G1 a np:Assertion.
#:G2 a np:Provenance.
#:G3 a np:Supporting.
#}
#:G1 {
#<http://purl.uniprot.org/uniprot/O76074>
#up:classifiedWith go:GO_0000287, go:GO_0005737, go:GO_0007165,
#go:GO_0008270, go:GO_0009187, go:GO_0030553.
#}
#:G2 {
#:nanopub1 pav:versionNumber "1.1"
#:nanopub1 pav:previousVersion "1.0".
#:nanopub1 dct:created "2009-09-03"^^xsd:date.
#:nanopub1 dct:creator ex:JohnSmith.
#:nanopub1 dct:rightsHolder ex:SomeOrganization.
#:nanopub1 up:citation <http://bio2rdf.org/medline:99320215>.
#}


}


1;
