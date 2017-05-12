use 5.010;
use lib "lib";
use lib "../RDF-RDFa-Generator/lib/";
use Data::Dumper;
use RDF::RDFa::Generator;
use RDF::RDFa::Linter;
use RDF::RDFa::Parser;
use RDF::TrineShortcuts;

my $html = <<'HTML';
<p vocab="http://schema.org/" typeof="Place">
	<span rel="sugarContent">
		<b typeof="Place">1</b>
	</span>
	<span property="numTracks">wrgfe6</span>
</p>
HTML
my $uri    = 'http://example.com/';
my $parser = RDF::RDFa::Parser->new($html, $uri, RDF::RDFa::Parser::Config->new('html5','1.1'));
my $linter = RDF::RDFa::Linter->new('SchemaOrg', $uri, $parser);

print Dumper($linter->find_errors);
