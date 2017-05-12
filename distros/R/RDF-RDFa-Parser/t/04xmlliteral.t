# Tests that XML Literals are working OK.

use Test::More tests => 8;
BEGIN { use_ok('RDF::RDFa::Parser') };
BEGIN { use_ok('XML::LibXML') };

my $xhtml = <<EOF;
<html xmlns:foaf="http://xmlns.com/foaf/0.1/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">
	<body xmlns:dc="http://purl.org/dc/elements/1.1/">
		<div rel="foaf:primaryTopic" rev="foaf:page">
			<h1 about="#topic" typeof="foaf:Person" property="foaf:name" 
                datatype="rdf:XMLLiteral"><strong>Albert Einstein</strong></h1>
		</div>
	</body>
</html>
EOF

$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/einstein');

ok(lc($parser->dom->documentElement->tagName) eq 'html', 'DOM Tree returned OK.');

ok($parser->consume, "Parse OK");

my $model;
ok($model = $parser->graph, "Graph retrieved");

my $iter = $model->get_statements(
	RDF::Trine::Node::Resource->new('http://example.com/einstein#topic'),
	RDF::Trine::Node::Resource->new('http://xmlns.com/foaf/0.1/name'),
	undef);
my $st = $iter->next;
ok(defined $st, "Literal found");

ok($st->object->literal_datatype eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral',
	"XML seems to have correct datatype");

SKIP: {
	skip("If you care about XML canonicalisation, upgrade to at least libxml 2.6.23.", 1)
		unless XML::LibXML::LIBXML_VERSION >= 20623;

	ok($st->object->literal_value eq '<strong xmlns="http://www.w3.org/1999/xhtml" xml:lang="de">Albert Einstein</strong>',
		"XML seems to have correct literal value (with ec14n)");
}


