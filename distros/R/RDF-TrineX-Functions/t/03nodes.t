use Test::More tests => 9;
use RDF::TrineX::Functions -all;

my $model = model();

ok(RDF::Trine::Node::Resource
	-> new('http://example.com/s')
	-> equal( iri('s', 'http://example.com/') )
);

ok(RDF::Trine::Node::Resource
	-> new('http://example.com/p')
	-> equal( iri('http://example.com/p') )
);

ok(RDF::Trine::Node::Resource
	-> new('http://example.com/p')
	-> equal( iri('http://example.com/p', 'http://example.net/') )
);

isa_ok iri('_:o') => RDF::Trine::Node::Blank;

isa_ok blank('_:o') => RDF::Trine::Node::Blank;

isa_ok blank('?o') => RDF::Trine::Node::Variable;

isa_ok variable('?o') => RDF::Trine::Node::Variable;

isa_ok literal('_:o') => RDF::Trine::Node::Literal;

ok(RDF::Trine::Node::Resource
	-> new('http://xmlns.com/foaf/0.1/name')
	-> equal( curie('foaf:name') )
);
