use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::Config;
use OpenGuides::RDF;
use OpenGuides::Utils;
use OpenGuides::Test;
use URI::Escape;
use Test::More;

eval { require DBD::SQLite; };
my $have_sqlite = $@ ? 0 : 1;

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

plan tests => 30;

# clear out the database
OpenGuides::Test::refresh_db();


my $config = OpenGuides::Test->make_basic_config;
$config->script_url( "http://wiki.example.com/" );
$config->script_name( "mywiki.cgi" );
$config->site_name( "Wiki::Toolkit Test Site" );
$config->default_city( "London" );
$config->default_country( "United Kingdom" );
$config->geo_handler( 3 );

eval { require Wiki::Toolkit::Search::Plucene; };
if ( $@ ) { $config->use_plucene ( 0 ) };


my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;


my $rdf_writer = eval {
    OpenGuides::RDF->new( wiki => $wiki, config => $config );
};
is( $@, "", "'new' doesn't croak if wiki and config objects supplied" );
isa_ok( $rdf_writer, "OpenGuides::RDF" );

# Test the data for a node that exists.
OpenGuides::Test->write_data(
        guide              => $guide,
        node               => "Calthorpe Arms",
        content            => "CAMRA-approved pub near King's Cross",
        comment            => "Stub page, please update!",
        username           => "Anonymous",
        postcode           => "WC1X 8JR",
        locales            => "Bloomsbury\r\nSt Pancras",
        phone              => "test phone number",
        website            => "http://example.com",
        hours_text         => "test hours",
        latitude           => "51.524193",
        longitude          => "-0.114436",
        summary            => "a really nice pub",
);

OpenGuides::Test->write_data(
        guide              => $guide,
        node               => "Calthorpe Arms",
        content            => "CAMRA-approved pub near King's Cross",
        comment            => "Stub page, please update!",
        username           => "Kake",
        postcode           => "WC1X 8JR",
        locales            => "Bloomsbury\r\nSt Pancras",
        phone              => "test phone number",
        website            => "http://example.com",
        hours_text         => "test hours",
        latitude           => "51.524193",
        longitude          => "-0.114436",
        summary            => "a nice pub",
        node_image         => "http://example.com/calthorpe.jpg",
);

my $rdfxml = $rdf_writer->emit_rdfxml( node => "Calthorpe Arms" );

like( $rdfxml, qr|<\?xml version="1.0" \?>|, "RDF uses no encoding when none set" );
$config->http_charset( "UTF-8" );
$guide = OpenGuides->new( config => $config );
$rdfxml = $rdf_writer->emit_rdfxml( node => "Calthorpe Arms" );
like( $rdfxml, qr|<\?xml version="1.0" encoding="UTF-8"\?>|, "RDF uses declared encoding" );

like( $rdfxml, qr|<foaf:depiction rdf:resource="http://example.com/calthorpe.jpg" />|, "Node image");

like( $rdfxml, qr|<wail:Neighborhood rdf:nodeID="Bloomsbury">|,
    "finds the first locale" );
like( $rdfxml, qr|<wail:Neighborhood rdf:nodeID="St_Pancras">|,
    "finds the second locale" );

like( $rdfxml, qr|<contact:phone>test phone number</contact:phone>|,
    "picks up phone number" );

like( $rdfxml, qr|<dc:available>test hours</dc:available>|,
    "picks up opening hours text" );

like( $rdfxml, qr|<foaf:homepage rdf:resource="http://example.com" />|, "picks up website" );

like( $rdfxml,
    qr|<dc:title>Wiki::Toolkit Test Site: Calthorpe Arms</dc:title>|,
    "sets the title correctly" );

like( $rdfxml, qr|id=Kake;format=rdf#obj"|,
    "last username to edit used as contributor" );
like( $rdfxml, qr|id=Anonymous;format=rdf#obj"|,
    "... as well as previous usernames" );

like( $rdfxml, qr|<wiki:version>2</wiki:version>|, "version picked up" );

like( $rdfxml, qr|<rdf:Description rdf:about="">|, "sets the 'about' correctly" );

like( $rdfxml, qr|<dc:source rdf:resource="http://wiki.example.com/mywiki.cgi\?Calthorpe_Arms" />|,
    "set the dc:source with the version-independent uri" );

like( $rdfxml, qr|<wail:City rdf:nodeID="city">\n\s+<wail:name>London</wail:name>|, "city" ).
like( $rdfxml, qr|<wail:locatedIn>\n\s+<wail:Country rdf:nodeID="country">\n\s+<wail:name>United Kingdom</wail:name>|, "country" ).
like( $rdfxml, qr|<wail:postalCode>WC1X 8JR</wail:postalCode>|, "postcode" );
like( $rdfxml, qr|<geo:lat>51.524193</geo:lat>|, "latitude" );
like( $rdfxml, qr|<geo:long>-0.114436</geo:long>|, "longitude" );
like( $rdfxml, qr|<dc:description>a nice pub</dc:description>|, "summary (description)" );

like( $rdfxml, qr|<dc:date>|, "date element included" );
unlike( $rdfxml, qr|<dc:date>1970|, "hasn't defaulted to the epoch" );

# Check that default city and country can be set to blank.
$config = OpenGuides::Test->make_basic_config;
$config->default_city( "" );
$config->default_country( "" );
$guide = OpenGuides->new( config => $config );
OpenGuides::Test->write_data(
                                guide => $guide,
                                node  => "Star Tavern",
                                latitude => 51.498,
                                longitude => -0.154,
                            );
$rdf_writer = OpenGuides::RDF->new( wiki => $guide->wiki, config => $config );
$rdfxml = $rdf_writer->emit_rdfxml( node => "Star Tavern" );
unlike( $rdfxml, qr|<city>|, "no city in RDF when no default city" );
unlike( $rdfxml, qr|<country>|, "...same for country" );

# Now test that there's a nice failsafe where a node doesn't exist.
$rdfxml = eval { $rdf_writer->emit_rdfxml( node => "I Do Not Exist" ); };
is( $@, "", "->emit_rdfxml doesn't die when called on a nonexistent node" );

like( $rdfxml, qr|<wiki:version>0</wiki:version>|, "...and wiki:version is 0" );

# Test the data for a node that redirects.
$wiki->write_node( "Calthorpe Arms Pub",
    "#REDIRECT [[Calthorpe Arms]]",
    undef,
    {
        comment  => "Created as redirect to Calthorpe Arms page.",
        username => "Earle",
    }
);

my $redirect_rdf = $rdf_writer->emit_rdfxml( node => "Calthorpe Arms Pub" );

like( $redirect_rdf, qr|<owl:sameAs rdf:resource="/\?id=Calthorpe_Arms;format=rdf#obj" />|,
    "redirecting node gets owl:sameAs to target" );

$wiki->write_node( "Nonesuch Stores",
    "A metaphysical wonderland",
    undef,
    {
        comment            => "Yup.",
        username           => "Nobody",
        opening_hours_text => "Open All Hours",
    }
);

$rdfxml = $rdf_writer->emit_rdfxml( node => "Nonesuch Stores" );

like( $rdfxml, qr|<geo:SpatialThing rdf:ID="obj">|,
    "having opening hours marks node as geospatial" );

