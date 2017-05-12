use lib "lib";

use RDF::RDFa::Generator;
use RDF::TrineShortcuts;

my $graph = rdf_parse(<<TURTLE, type=>'turtle');

\@prefix foaf: <http://xmlns.com/foaf/0.1/> .
\@prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .

<http://example.net/>

	a foaf:Document ;
	<http://www.w3.org/1999/xhtml/vocab#next> <http://example.net/page2> ;
	<http://www.w3.org/1999/xhtml/vocab#title> "About Joe"@en ;
	foaf:primaryTopic [
		a foaf:Person ;
		foaf:name "Joe Bloggs" ;
		foaf:plan "To conquer the world!"\@en
	] ;
	foaf:utf8 "fæces" ;
	foaf:segment "Hello <b xmlns='http://www.w3.org/1999/xhtml'>World</b>"^^rdf:XMLLiteral .

TURTLE

my @nodes = RDF::RDFa::Generator->new(style=>'HTML::Head')->nodes($graph,id_prefix=>'id-',interlink=>'see also');
print $_->toString foreach @nodes;
