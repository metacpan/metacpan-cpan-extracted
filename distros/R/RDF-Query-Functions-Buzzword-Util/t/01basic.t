use Test::More tests => 1;
use RDF::Query;

ok(
	defined $RDF::Query::functions{'http://buzzword.org.uk/2011/functions/util#uuid'},
	"Module::Pluggable found me!",
	);