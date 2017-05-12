# Tests that base URLs are working OK.

use Test::More tests => 12;
BEGIN { use_ok('RDF::RDFa::Parser') };

my $xhtml_rdfa_10 = RDF::RDFa::Parser::Config->new('xhtml','1.0');

my ($parser, $model);
my $xhtml = <<EOF;
<html
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:ex="http://example.com/ns#"
	xmlns:http="http://example.com/http#"
	xml:lang="en">
	<body>
		<div about="[ex:r1/foo]" rel="ex:test" resource="[ex:test]" />
		<div about="[ex:r2]" rel="ex:r2/foo" resource="[ex:test]" />
		<div about="[ex:r3]" rel=":TEST" resource="[ex:test]" />
		<div about="[ex:r4]" rel="ex:r4" href="[ex:r4]" />
		<div about="[ex:r5]" rel="ex:r5" resource="[ex:r5]" />
		<div about="[ex:r6]" rel="arkansas" resource="[ex:r6]" />
		<div about="http://example.net/1" rel="ex:test" resource="[ex:test]" />
		<div about="[http://example.net/2]" rel="ex:test" resource="[ex:test]" />
	</body>
</html>
EOF

$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/', $xhtml_rdfa_10);
$parser->consume;
$model = $parser->graph;

#my $iter = $model->as_stream;
#while (my $st = $iter->next)
#{
#	diag $st->as_string;
#}

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1/foo'),
		undef,
		undef,
		),
	"Supports non-QName characters in SafeCURIEs.");

ok($model->count_statements(
		undef,
		RDF::Trine::Node::Resource->new('http://example.com/ns#r2/foo'),
		undef,
		),
	"Supports non-QName characters in CURIEs.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r3'),
		RDF::Trine::Node::Resource->new('http://www.w3.org/1999/xhtml/vocab#TEST'),
		undef,
		),
	"Default prefix works.");

ok(!$model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r4'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#r4'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#r4'),
		),
	"Safe CURIEs don't work in \@href.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r5'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#r5'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#r5'),
		),
	"Safe CURIEs work in \@resource.");

ok(!$model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r6'),
		undef,
		RDF::Trine::Node::Resource->new('http://example.com/ns#r6'),
		),
	"Nonsense keywords ignored.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.net/1'),
		undef,
		undef,
		),
	"http-URI recognised.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/http#//example.net/2'),
		undef,
		undef,
		),
	"http-URI-looking CURIE recognised.");

$xhtml = <<EOF;
<html
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:ex="http://example.com/ns#"
	xmlns:http="http://example.com/http#"
	xml:lang="en">
	<body>
		<div about="[ex:r1]" rel="http://example.com/ https://example.com/" resource="[ex:r1]" />
	</body>
</html>
EOF

$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/', $xhtml_rdfa_10);
$parser->consume;
$model = $parser->graph;

ok(1==$model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		undef,
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		),
	"Undefined CURIE ignored.");

$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/', {'full_uris'=>1});
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		RDF::Trine::Node::Resource->new('http://example.com/http#//example.com/'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		),
	"http-URI-looking CURIE recognised, even if full URIs enabled.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		RDF::Trine::Node::Resource->new('https://example.com/'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		),
	"Full URI recognised.");
