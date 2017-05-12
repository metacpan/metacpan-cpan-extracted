use Test::More tests => 1;
use RDF::KML::Exporter;

my $data = [<<'TURTLE', as => 'Turtle', base => 'http://example.com/'];

@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix geo:  <http://www.w3.org/2003/01/geo/wgs84_pos#> .

[]
	rdfs:label "Test"@en ;
	a geo:Point ;
	geo:lat 1.23 ;
	geo:long 4.56 .

[]
	a geo:Point ;
	geo:alt 0;
	geo:lat 7.23 ;
	geo:long 8.56 .

TURTLE

my $kml = RDF::KML::Exporter->new->export_kml($data);

like(
	$kml->render,
	qr{
		<Placemark>
			<name>Test</name>
			<Snippet.maxLines="0"/>
			<Point>
				<coordinates>4.56,1.23,0</coordinates>
			</Point>
		</Placemark>
	}x
);
