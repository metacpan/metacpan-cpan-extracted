# Test the very basics.

use Test::More tests => 6;
BEGIN { use_ok('RDF::RDFa::Parser') };

use RDF::Trine;

my $xhtml = <<EOF;
<html
	xmlns:dc="http://purl.org/dc/terms/"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xml:lang="en">

	<head>
		<title property="dc:title">This is the title</title>
	</head>

	<body xmlns:dc="http://purl.org/dc/elements/1.1/">
		<div rel="foaf:primaryTopic foam:topic" rev="foaf:page" xml:lang="de">
			<h1 about="#topic" typeof="foaf:Person" property="foaf:name">Albert Einstein</h1>
		</div>
		<address rel="foaf:maker dc:creator" rev="foaf:made">
			<a about="#maker" property="foaf:name" rel="foaf:homepage" href="joe">Joe Bloggs</a>
		</address>
	</body>

</html>
EOF

$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/einstein');

$parser->set_callbacks({pretriple_literal => sub{
	if ($_[2] eq 'http://example.com/einstein#maker'
	&&  $_[3] eq 'http://xmlns.com/foaf/0.1/name')
	{
		ok($_[4] eq 'Joe Bloggs', 'Callbacks working OK.');
	}
	return 0;
},
ontoken => sub{
	if ($_[2] eq 'foam:topic')
	{
		return 'http://xmlns.com/foaf/0.1/topic';
	}
	return $_[3];
}});

ok(lc($parser->dom->documentElement->tagName) eq 'html', 'DOM Tree returned OK.');

$parser->consume;
my $model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/einstein'),
		RDF::Trine::Node::Resource->new('http://purl.org/dc/elements/1.1/creator'),
		RDF::Trine::Node::Resource->new('http://example.com/einstein#maker')
		),
	'RDFa graph looks OK (tested a resource).');

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/einstein#topic'),
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
		RDF::Trine::Node::Literal->new('Albert Einstein', 'de')
		),
	'RDFa graph looks OK (tested a literal).');

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/einstein'),
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/topic'),
		RDF::Trine::Node::Resource->new('http://example.com/einstein#topic')
		),
	'oncurie CURIE rewriting worked.');

