# Tests that base URLs are working OK.

use Test::More tests => 14;
BEGIN { use_ok('RDF::RDFa::Parser') };

my ($parser, $model);
my $xhtml = <<EOF;
<html
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:ex="http://example.com/ns#"
	xml:lang="en">
	<head>
		<base href="http://example.com/html" />
	</head>
	<body xml:base="http://example.com/xml">
		<div about="#about" rel="ex:test" resource="#resource" />
		<div src="#src" rel="ex:test" href="#href" />
	</body>
</html>
EOF

my $config = RDF::RDFa::Parser::Config->new('xhtml', '1.0');
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', $config);
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/html#about'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/html#resource'),
		),
	"Default behaviour respects BASE element - about and resource.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/html#src'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/html#href'),
		),
	"Default behaviour respects BASE element - src and href.");

$config = RDF::RDFa::Parser::Config->new('xhtml', '1.0', xhtml_base=>0);
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', $config);
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/perl#about'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/perl#resource'),
		),
	"Can switch off BASE element - about and resource.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/perl#src'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/perl#href'),
		),
	"Can switch off BASE element - src and href.");

$config = RDF::RDFa::Parser::Config->new('xhtml', '1.0', xml_base=>1);
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', $config);
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/xml#about'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/xml#resource'),
		),
	"Can switch on xml:base attribute selectively - about and resource.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/html#src'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/html#href'),
		),
	"Can switch on xml:base attribute selectively - src and href don't use it.");

$config = RDF::RDFa::Parser::Config->new('xhtml', '1.0', xml_base=>2);
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', $config);
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/xml#about'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/xml#resource'),
		),
	"Can switch on xml:base attribute completely - about and resource.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/xml#src'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/xml#href'),
		),
	"Can switch on xml:base attribute completely - src and href.");

$config = RDF::RDFa::Parser::Config->new('xhtml', '1.0', xml_base=>1,xhtml_base=>0);
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', $config);
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/xml#about'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/xml#resource'),
		),
	"Can switch on xml:base attribute and switch off BASE element at the same time - about and resource.");

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/perl#src'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/perl#href'),
		),
	"Can switch on xml:base attribute and switch off BASE element at the same time - src and href.");

$xhtml = <<EOF;
<html
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:ex="http://example.com/ns#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xml:lang="en">
	<head>
		<base href="http://example.com/html" />
	</head>
	<body xml:base="http://example.com/xml">
		<rdf:RDF>
			<rdf:Description rdf:about="#rdfabout">
				<ex:foo rdf:resource="#rdfresource" />
			</rdf:Description>
		</rdf:RDF>
	</body>
</html>
EOF

$config = RDF::RDFa::Parser::Config->new('xhtml', '1.0', xml_base=>0,embedded_rdfxml=>1);
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', $config);
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/xml#rdfabout'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#foo'),
		RDF::Trine::Node::Resource->new('http://example.com/xml#rdfresource'),
		),
	"RDF/XML respects xml:base always.");

$xhtml = <<EOF;
<html
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:ex="http://example.com/ns#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xml:lang="en">
	<head>
		<base href="http://example.com/html" />
	</head>
	<body>
		<rdf:RDF>
			<rdf:Description rdf:about="#rdfabout">
				<ex:foo rdf:resource="#rdfresource" />
			</rdf:Description>
		</rdf:RDF>
	</body>
</html>
EOF

$config = RDF::RDFa::Parser::Config->new('xhtml', '1.0', xml_base=>0,xhtml_base=>2,embedded_rdfxml=>1);
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', $config);
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/html#rdfabout'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#foo'),
		RDF::Trine::Node::Resource->new('http://example.com/html#rdfresource'),
		),
	"RDF/XML respects BASE element if you're crazy.");

$xhtml = <<EOF;
<html
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:ex="http://example.com/ns#"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xml:lang="en">
	<head>
		<base href="http://example.com/html" />
	</head>
	<body xml:base="http://example.com/xml-rubbish">
		<div xml:base="http://example.com/xml">
			<div about="#about" rel="ex:test" resource="#resource" />
		</div>
	</body>
</html>
EOF

$config = RDF::RDFa::Parser::Config->new('xhtml', '1.0', xml_base=>1);
$parser = RDF::RDFa::Parser->new($xhtml, 'http://example.com/perl', {xml_base=>1});
$parser->consume;
$model = $parser->graph;

ok($model->count_statements(
		RDF::Trine::Node::Resource->new('http://example.com/xml#about'),
		RDF::Trine::Node::Resource->new('http://example.com/ns#test'),
		RDF::Trine::Node::Resource->new('http://example.com/xml#resource'),
		),
	"Nesting xml:base works.");