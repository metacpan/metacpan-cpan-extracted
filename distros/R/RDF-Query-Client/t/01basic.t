use LWP::UserAgent;
use Test::RequiresInternet 'sparql.org' => 80;
use Test::More tests => 5;

BEGIN { use_ok('RDF::Query::Client') };

SKIP:
{
	my $response = LWP::UserAgent
		-> new
		-> get('http://sparql.org/books/sparql?query=SELECT+*+{$s+$p+$o}');
	
	unless ($response->is_success)
	{
		diag $response->as_string;
		skip "need network access and ability to connect to sparql.org", 4;
	}
	
	my $sparql_ask
		= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
		. "ASK WHERE { ?book dc:title ?title . }" ;
	
	my $sparql_select
		= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
		. "SELECT * WHERE { ?book dc:title ?title . }" ;
	
	my $sparql_construct
		= "PREFIX dc: <http://purl.org/dc/elements/1.1/>\n"
		. "CONSTRUCT { ?book <http://purl.org/dc/terms/title> ?title . }\n"
		. "WHERE { ?book dc:title ?title . }" ;
		
	my $q_ask       = new RDF::Query::Client($sparql_ask);
	my $q_select    = new RDF::Query::Client($sparql_select);
	my $q_construct = new RDF::Query::Client($sparql_construct);
	
	my $r_ask       = $q_ask->execute('http://sparql.org/books/sparql');
	my $r_select    = $q_select->execute('http://sparql.org/books/sparql');
	my $r_construct = $q_construct->execute('http://sparql.org/books/sparql');
	
	ok($r_ask->is_boolean, "ASK results in a boolean");
	ok($r_select->is_bindings, "SELECT results in bindings");
	ok($r_construct->is_graph, "CONSTRUCT results in a graph");
	
	ok($r_ask->get_boolean, "ASK results as expected");
	
	diag("You can safely ignore warnings from DBD about tables being locked.\n");
}
