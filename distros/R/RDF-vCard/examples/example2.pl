use Data::Dumper;
use RDF::TrineX::Functions -shortcuts;
use HTML::Microformats;
use RDF::vCard;
use RDF::vCard::Importer;
use JSON -convert_blessed_universally;

my $html = <<'HTML';
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Example</title>
	</head>
	<body>
		<div class="vcard">
			<h1><a href="/" class="fn url">Alice Jones</a></h1>
			<p class="adr"><span class="locality">Lewes</span>, <span class="region">East Sussex</span></p>
			<div class="agent vcard">
				<span class="role">Secretary</span>
				<a class="fn email" href="mailto:bob@example.com">Bob Smith</a>
			</div>
			<div>Updated: <span class="rev">2011-01-06T11:00:00Z</span></div>
		</div>
	</body>
</html>
HTML

my $doc = HTML::Microformats->new_document($html, "http://example.com/", type=>'application/xhtml+xml')->assume_all_profiles;

my $model = rdf_parse(<<'MORE', type=>'turtle', model => $doc->model, base => 'http://example.net/base/');
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix v: <http://www.w3.org/2006/vcard/ns#> .
@prefix vx: <http://buzzword.org.uk/rdf/vcardx#> .

<http://example.net/taxo/Quux> rdf:value "Quux" .

  <http://example.com/> a v:VCard ;
     v:fn "Example.Com LLC" ;
     v:org
         [   v:organisation-name "Dewey, Cheatem and Howe" ;
             v:organisation-unit "Corporate Division"
         ] ;
	  vx:category <http://example.net/taxo/Quux> , <http://example.net/taxo/Xyzzy> ;
	  v:category "Corporate", "Foobar";
     v:logo <data:image/gif;base64,R0lGODdhIAAgAIAAAAAAAPj8+CwAAAAAIAAgAAAClYyPqcu9AJyCjtIKc5w5xP14xgeO2tlY3nWcajmZZdeJcGKxrmimms1KMTa1Wg8UROx4MNUq1HrycMjHT9b6xKxaFLM6VRKzI+pKS9XtXpcbdun6uWVxJXA8pNPkdkkxhxc21LZHFOgD2KMoQXa2KMWIJtnE2KizVUkYJVZZ1nczBxXlFopZBtoJ2diXGdNUymmJdFMAADs=> ;
     v:homeAdr
         [ a v:Work ;
             v:country-name "Australia" ;
             v:locality "WonderLand", "WonderCity" ;
             v:postal-code "5555" ;
             v:street-address "33 Enterprise Drive"
         ] ;
     v:geo
         [ v:latitude "43.33" ;
             v:longitude "55.45"
         ] ;
     v:tel
         [ a v:Fax, v:Work ;
             rdf:value "+61 7 5555 0000"
         ] ; 
     v:email <mailto:info@example.com> ;
     v:logo <http://example.com/logo.png> .
MORE

my $exporter = RDF::vCard::Exporter->new;
my @cards = $exporter->export_cards($model);
my $cards = join "", @cards;

my $importer = RDF::vCard::Importer->new;
my @rv = $importer->import_string($cards);
print $cards;
print Dumper([ @rv ]);
print rdf_string($importer->model => 'RDFXML');
