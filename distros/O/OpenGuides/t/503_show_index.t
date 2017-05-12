use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

eval { require Test::HTML::Content; };
my $thc = $@ ? 0 : 1;

plan tests => 44;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->script_name( "wiki.cgi" );
$config->script_url( "http://example.com/" );
my $guide = OpenGuides->new( config => $config );
isa_ok( $guide, "OpenGuides" );
my $wiki = $guide->wiki;
isa_ok( $wiki, "Wiki::Toolkit" );


$wiki->write_node( "Test Page", "foo", undef,
                   { category => "Alpha", locale => "Assam",
                     latitude => 51.754349, longitude => -1.258200 } )
  or die "Couldn't write node";
$wiki->write_node( "Test Page 2", "foo", undef,
                   { category => "Alpha", locale => "Assam" } )
  or die "Couldn't write node";
$wiki->write_node( "Test Page 3", "foo", undef,
                   { category => "Beta", locale => "Bangalore",
                     latitude => 51.8, longitude => -0.8 } )
  or die "Couldn't write node";

# Make sure that old-style invocations redirect to new.
my $output = $guide->show_index( type => "category", value => "Alpha",
                                 return_output => 1, intercept_redirect => 1 );
like( $output, qr/Status: 301/,
      "Old-style category index search prints a redirect" );
like( $output, qr/cat=alpha/, "...and includes the correct param/value pair" );

$output = $guide->show_index( type => "locale", value => "Assam",
                              return_output => 1, intercept_redirect => 1,
                              format => "map" );
like( $output, qr/Status: 301/,
      "Old-style locale index search prints a redirect" );
like( $output, qr/loc=assam/, "...and includes the correct param/value pair" );
like( $output, qr/format=map/, "...format parameter included too" );

# Test the normal, HTML version
$output = eval {
    $guide->show_index(
                        cat           => "Alpha",
                        return_output => 1,
                        noheaders     => 1,
                      );
};
is( $@, "", "->show_index doesn't die" );
like( $output, qr|wiki.cgi\?Test_Page|, "...and includes correct links" );
unlike( $output, qr|wiki.cgi\?Test_Page_3|, "...but not incorrect ones" );
unlike( $output, qr|<title>\s*-|, "...sets <title> correctly" );

# Test links in the header.
like( $output, qr|<link rel="alternate[^>]*action=index;cat=alpha;format=rss|,
      "RSS link correct in header" );
like( $output, qr|<link rel="alternate[^>]*action=index;cat=alpha;format=atom|,
      "Atom link correct in header" );

# Test links in the footer.
my $footer = $output;
$footer =~ s/^.*This list is available as//s;
$footer =~ s|</p>.*$||s;
like( $footer, qr|action=index;cat=alpha;format=rdf|,
      "RDF link correct in footer" );
like( $footer, qr|action=index;cat=alpha;format=rss|,
      "RSS link correct in footer" );
like( $footer, qr|action=index;cat=alpha;format=atom|,
      "Atom link correct in footer" );

# When using leaflet, test link to map version in body.
SKIP: {
    skip "Test::HTML::Content not available", 1 unless $thc;
    $config->use_leaflet( 1 );
    Test::HTML::Content::link_ok( $output,
        "http://example.com/wiki.cgi?action=index;cat=alpha;format=map",
        "We have a link to the map version" );
}

# Test the RDF version
$output = $guide->show_index(
                              cat           => "Alpha",
                              return_output => 1,
                              format        => "rdf"
                            );
like( $output, qr|Content-Type: application/rdf\+xml|,
      "RDF output gets content-type of application/rdf+xml" );
like( $output, qr|<rdf:RDF|, "Really is rdf" );
like( $output, qr|<dc:title>Category Alpha</dc:title>|, "Right rdf title" );
my @entries = ($output =~ /(\<rdf\:li\>)/g);
is( 2, scalar @entries, "Right number of nodes included in rdf" );

# Test the RSS version
$output = eval {
    $guide->show_index(
                        cat           => "Alpha",
                        return_output => 1,
                        format        => "rss",
                      );
};
is( $@, "", "->show_index doesn't die when asked for rss" );
like( $output, qr|Content-Type: application/rdf\+xml|,
      "RSS output gets content-type of application/rdf+xml" );
like( $output, "/\<rdf\:RDF.*?http\:\/\/purl.org\/rss\//s", "Really is rss" );
like( $output, qr|<title>Test - Index of Category Alpha</title>|,
      "Right rss title" );
@entries = ($output =~ /(\<\/item\>)/g);
is( 2, scalar @entries, "Right number of nodes included in rss" );

# Test the Atom version
$output = eval {
    $guide->show_index(
                        cat           => "Alpha",
                        return_output => 1,
                        format        => "atom",
                      );
};
is( $@, "", "->show_index doesn't die when asked for atom" );
like( $output, qr|Content-Type: application/atom\+xml|,
      "Atom output gets content-type of application/atom+xml" );
like( $output, qr|<feed|, "Really is atom" );
like( $output, qr|<title>Test - Index of Category Alpha</title>|,
      "Right atom title" );
@entries = ($output =~ /(\<entry\>)/g);
is( 2, scalar @entries, "Right number of nodes included in atom" );


# Test the map version
# They will need a Helmert Transform provider for this to work
$config->gmaps_api_key("yes I have one");
$config->geo_handler(1);
$config->force_wgs84(0);

my $has_helmert = 0;
eval {
    use OpenGuides::Utils;
    $has_helmert = OpenGuides::Utils->get_wgs84_coords(latitude=>1,longitude=>1,config=>$config);
};

SKIP: {
    skip "No Helmert Transform provider installed, can't test geo stuff", 6
      unless $has_helmert;

    # This is testing the legacy stuff.
    $config->use_leaflet( 0 );

    $output = eval {
        $guide->show_index(
                            return_output => 1,
                            loc           => "assam",
                            format        => "map",
                          );
    };
    is( $@, "", "Using GMaps: ->show_index doesn't die when asked for map" );
    like( $output, qr|Content-Type: text/html|,
          "...map output gets content-type of text/html" );
    like( $output, qr|new GMap|, "...really is google map" );
    my @points = ($output =~ /point\d+ = (new GPoint\(.*?, .*?\))/g);
    is( 1, scalar @points, "...right number of nodes included on map" );

    # -1.259687,51.754813
    like( $points[0], qr|51.75481|, "...has latitude");
    like( $points[0], qr|-1.25968|, "...has longitude");
}

# But we don't want the GMaps stuff if we're using Leaflet.
$config->use_leaflet( 1 );

$output = eval {
    $guide->show_index(
                        return_output => 1,
                        loc           => "assam",
                        format        => "map",
                      );
};

is( $@, "", "Using Leaflet: ->show_index doesn't die when asked for map" );
like( $output, qr|Content-Type: text/html|,
      "...map output gets content-type of text/html" );
unlike( $output, qr|new GMap|, "...no invocation of GMap constructor" );
unlike ( $output, qr|new GPoint|, "...nor GPoint" );

# Test links in the header (only implemented for Leaflet).
like( $output,
      qr|<link rel="alternate[^>]*action=index;loc=assam;format=rss|,
      "RSS link correct in header" );
like( $output,
      qr|<link rel="alternate[^>]*action=index;loc=assam;format=atom|,
      "Atom link correct in header" );

SKIP: {
    skip "Test::HTML::Content not available", 1 unless $thc;
    # Do this again to get a version without headers, so T::H::C doesn't whine.
    $output = $guide->show_index(
                                  return_output => 1,
                                  loc           => "assam",
                                  format        => "map",
                                  noheaders     => 1,
                                );
    Test::HTML::Content::link_ok( $output,
        "http://example.com/wiki.cgi?action=index;loc=assam",
        "We have a link to the non-map version" );
}
