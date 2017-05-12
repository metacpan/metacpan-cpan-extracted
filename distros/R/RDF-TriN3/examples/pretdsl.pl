#!/usr/bin/perl

use 5.010;
use RDF::TriN3;
use RDF::TrineX::Parser::Pretdsl;

# Namespaces are just for Turtle output!
my $ns = {
	cpant   => 'http://purl.org/NET/cpan-uri/terms#',
	cpan    => 'http://purl.org/NET/cpan-uri/person/',
	dbug    => 'http://ontologi.es/doap-bugs#',
	dcs     => 'http://ontologi.es/doap-changeset#',
	dcterms => 'http://purl.org/dc/terms/',
	dist    => 'http://purl.org/NET/cpan-uri/dist/Example-Distribution/',
	doap    => 'http://usefulinc.com/ns/doap#',
	foaf    => 'http://xmlns.com/foaf/0.1/',
	nfo     => 'http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#',
	rdfs    => 'http://www.w3.org/2000/01/rdf-schema#',
	rev     => 'http://purl.org/stuff/rev#',
	xsd     => 'http://www.w3.org/2001/XMLSchema#',
};

my $pretdsl = <<'DATA';

@prefix ex: <http://example.net/> .

`Example-Distribution`
doap:developer cpan:TOBYINK ;
doap:maintainer cpan:TOBYINK .

`Example-Distribution 0.000_01 cpan:TOBYINK`
issued 2012-06-17 .

`Example-Distribution 0.001 cpan:TOBYINK`
issued 2012-06-18 .

`Example-Distribution 0.002 cpan:TOBYINK`
issued 2012-06-19 ;
provides `Example::Distribution Example-Distribution 0.002 cpan:TOBYINK` ;
provides `Example::Distribution::Helper Example-Distribution 0.002 cpan:TOBYINK` ;
dcs:hasPart `./README Example-Distribution 0.002 cpan:TOBYINK` ;
changeset [
	item "More monkey madness!"^^Addition ;
	item "Less lion laziness!"^^Removal ;
	item [ a dcs:Bugfix ; dcs:fixes RT#12345 ; label "Too much focus on lazy cats, but not enough focus on excited primates." ] ;
] .

`Example::Distribution Example-Distribution 0.002 cpan:TOBYINK`
ex:defines p`Example::Distribution 0.002`.
`Example::Distribution::Helper Example-Distribution 0.002 cpan:TOBYINK`
ex:defines p`Example::Distribution::Helper`.

DATA

my $model = RDF::Trine::Model->new;

RDF::TrineX::Parser::Pretdsl
	-> new
	-> parse_into_model('http://example.org/', $pretdsl, $model);

print RDF::Trine::Serializer
	-> new('Turtle', namespaces => $ns)
	-> serialize_model_to_string($model);
