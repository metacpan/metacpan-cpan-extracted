use 5.010;
use lib "lib";
use lib "../RDF-RDFa-Generator/lib/";
use Data::Dumper;
use RDF::RDFa::Generator;
use RDF::RDFa::Linter;
use RDF::RDFa::Parser;
use RDF::TrineShortcuts;

my $html = <<'HTML';
<html prefix="og: http://ogp.me/ns# book: http://ogp.me/ns/book#">
<meta property="og:flibble" content="lghh" />
<meta property="og:url" content="/" />
<meta property="og:type" content="video" />
<meta property="og:type" content="munchkin:moo" />
<meta property="book:release_date" content="20080101" />
<p vocab="http://schema.org/" typeof="Place">
	<span rel="sugarContent">
		<b typeof="Place">1</b>
	</span>
	<span property="numTracks">wrgfe6</span>
</p>
HTML
my $uri    = 'http://example.com/';
my $parser = RDF::RDFa::Parser->new($html, $uri, RDF::RDFa::Parser::Config->new('html5','1.1'));
my $linter = RDF::RDFa::Linter->new('Facebook', $uri, $parser);

print Dumper($linter->find_errors);
print rdf_string($linter->filtered_graph => 'Turtle');
