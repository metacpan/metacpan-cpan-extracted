use Test::More tests => 10;
use RDF::Prefixes;

my $context = RDF::Prefixes->new;

ok(!keys %$context,
	"Empty context is really empty." );

$context->preview_prefix('http://example.com/foaf/');
ok(!keys %$context,
	"preview_prefix does not modify context." );

is($context->get_prefix('http://xmlns.com/foaf/0.1/'),
	'foaf',
	'sensible prefix chosen - ignores version number');

is($context->get_prefix('http://xmlns.com/foaf/1.0/'),
	'foaf2',
	'sensible prefix chosen - avoids clash');

is($context->get_prefix('http://example.com/foo.rdf#'),
	'foo',
	'sensible prefix chosen - ignores extension');

is($context->get_qname('http://example.com/foo.rdf#bar'),
	'foo:bar',
	'get_qname works');

ok(!defined $context->get_qname('http://example.com/foo.rdf#0'),
	'get_qname returns undef appropriately');

my $foo0 = $context->get_curie('http://example.com/foo.rdf#0');
ok($foo0,
	'get_curie returns something when get_qname cannot');
	
is($context->{ substr($foo0, 0, (length $foo0) - 1) },
	'http://example.com/foo.rdf#0',
	'get_curie returned something sensible!');

is("$context", <<'TURTLE', "output seems OK");
@prefix foaf:  <http://xmlns.com/foaf/0.1/> .
@prefix foaf2: <http://xmlns.com/foaf/1.0/> .
@prefix foo:   <http://example.com/foo.rdf#> .
@prefix foo2:  <http://example.com/foo.rdf#0> .
TURTLE
