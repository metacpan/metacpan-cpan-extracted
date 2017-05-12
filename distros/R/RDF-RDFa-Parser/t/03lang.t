# Tests that lang tags work properly

use Test::More tests => 8;
BEGIN { use_ok('RDF::RDFa::Parser') };

my $xhtml_rdfa_10 = RDF::RDFa::Parser::Config->new('xhtml','1.0');

my $xhtml = <<EOF;
<html xmlns:ex="http://example.com/ns#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns="http://www.w3.org/1999/xhtml"
	xml:lang="en-gb">
	<body>
		<div about="[ex:r0]" property="ex:test" content="English" />
		<div lang="de" about="[ex:r1]" property="ex:test" content="English" />
		<div xml:lang="invalid-lang-tags" about="[ex:r2]" property="ex:test" content="English" />
		<div xml:lang="" about="[ex:r3]" property="ex:test" content="Empty" />
	</body>
</html>
EOF

my $parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/', $xhtml_rdfa_10);
$parser->consume;

my $model;
ok($model = $parser->graph, "Graph retrieved");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r0'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Literal->new('English', 'en-gb'),
		),
	"Language tags are being picked up.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Literal->new('English', 'en-gb'),
		),
	"Non-XML lang tags are correctly ignored.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r2'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Literal->new('English', 'en-gb'),
		),
	"Invalid XML lang tags are correctly ignored.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r3'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Literal->new('Empty'),
		),
	"Empty XML lang tags reset the language.");


$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/', {xhtml_lang=>1});
$parser->consume;
ok($model = $parser->graph, "Alternative graph retrieved");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/ns#r1'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Literal->new('English', 'de'),
		),
	"XHTML lang tags are not ignored when that option is requested.");
