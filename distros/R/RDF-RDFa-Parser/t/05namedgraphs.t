use Test::More tests => 7;
BEGIN { use_ok('RDF::RDFa::Parser') };

use RDF::RDFa::Parser;

my $xhtml = <<EOF;
<html xmlns:dc="http://purl.org/dc/terms/" xmlns:foaf="http://xmlns.com/foaf/0.1/" xml:lang="en"
xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title property="dc:title">This is the title</title>
	</head>
	<body xmlns:dc="http://purl.org/dc/elements/1.1/">
		<div rel="foaf:primaryTopic" rev="foaf:page" xml:lang="de">
			<h1 about="#topic" typeof="foaf:Person" property="foaf:name">Albert Einstein</h1>
		</div>
		<address rel="foaf:maker dc:creator" rev="foaf:made" xmlns:g="http://example.com/graphing">
			<a g:graph="#JOE" about="#maker" property="foaf:name" rel="foaf:homepage" href="joe">Joe Bloggs</a>
		</address>
	</body>
</html>
EOF
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/einstein',
	{
		graph => 1,
		graph_attr => '{http://example.com/graphing}graph',
		graph_type => 'about',
	});
$parser->consume;

ok($parser->graph('http://example.com/einstein#JOE')->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/einstein#maker'),
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
		RDF::Trine::Node::Literal->new('Joe Bloggs', 'en')
		),
	"The graph(uri) method returns the appropriate graph");

ok(!$parser->graph('_:RDFaDefaultGraph')->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/einstein#maker'),
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
		RDF::Trine::Node::Literal->new('Joe Bloggs', 'en')
		),
	"Statement in a non-default graph isn't duplicated in the default graph.");

ok($parser->graphs->{'http://example.com/einstein#JOE'}->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/einstein#maker'),
		RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
		RDF::Trine::Node::Literal->new('Joe Bloggs', 'en')
		),
	"The graphs() method returns a hashref of graphs");

my $iter = $parser->graph->get_statements(
	RDF::Trine::Node::Resource->new('http://example.com/einstein#maker'),
	RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
	RDF::Trine::Node::Literal->new('Joe Bloggs', 'en'),
	RDF::Trine::Node::Resource->new('http://example.com/einstein#JOE'));
my $st = $iter->next;
isa_ok($st, 'RDF::Trine::Statement::Quad');
isa_ok($st->context, 'RDF::Trine::Node::Resource');
ok($st->context->uri eq 'http://example.com/einstein#JOE', "Graph URI looks OK.");
