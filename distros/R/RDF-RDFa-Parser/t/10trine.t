use Test::More tests => 6;
use RDF::Trine qw(iri literal);
use RDF::TrineX::Parser::RDFa;
use Data::Dumper;

my $parser = new_ok 'RDF::Trine::Parser' => ['xhtmlrdfa11'];
isa_ok $parser => 'RDF::Trine::Parser';
isa_ok $parser => 'RDF::TrineX::Parser::RDFa';
isa_ok $parser => 'RDF::TrineX::Parser::XHTML_RDFa11';
can_ok $parser => qw(
	parse_url_into_model
	parse_into_model
	parse
	parse_file_into_model
	parse_file
);

my $model = RDF::Trine::Model->new;
$parser->parse_file_into_model(
	'http://www.example.com/',
	\*DATA  => $model,
	context => iri('http://www.example.com/graph'),
);

ok(
	$model->count_statements(
		iri('http://www.example.com/'),
		iri('http://purl.org/dc/terms/title'),
		literal('Hello', 'en'),
		iri('http://www.example.com/graph'),
	)
);


__DATA__
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
	<head>
		<title property="dc:title">Hello</title>
	</head>
	<body>
		<p>Hello World</p>
	</body>
</html>

