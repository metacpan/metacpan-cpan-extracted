use lib "lib";
use RDF::Trine qw[iri literal];
use RDF::Closure::RestrictedDatatype;
use RDF::Closure qw[$XSD $RDF $RDFS $OWL];

my $rdt1 = RDF::Closure::RestrictedDatatype->new(
	'http://example.com/lownum',
	$XSD->integer->uri,
	[
		[ $XSD->minInclusive, literal(0, undef, $XSD->integer->uri) ],
		[ $XSD->maxExclusive, literal(10, undef, $XSD->integer->uri) ],
	],
	);

my $test1 = literal(10, undef, $XSD->integer->uri);
print $rdt1->check($test1) ? "Pass\n" : "Fail\n";

my $rdt2 = RDF::Closure::RestrictedDatatype->new(
	'http://example.com/mystring',
	$RDF->PlainLiteral->uri,
	[
		[ $XSD->minLength, literal(4, undef, $XSD->integer->uri) ],
		[ $XSD->maxLength, literal(10, undef, $XSD->integer->uri) ],
		[ $XSD->pattern, literal('^[Hh]ello$', undef, $XSD->regexp->uri) ],
		[ $RDF->langRange, literal('en-gb', undef, $XSD->lang->uri) ],
		[ $RDF->langRange, literal('en-*-oed', undef, $XSD->lang->uri) ],
	],
	);

my $test2 = literal('Hello@en-gb-oed', undef, $RDF->PlainLiteral->uri);
print $rdt2->check($test2) ? "Pass\n" : "Fail\n";
