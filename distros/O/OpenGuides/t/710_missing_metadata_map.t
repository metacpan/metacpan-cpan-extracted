use strict;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite not available ($error)";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not available";
}

plan tests => 18;

OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write four nodes, all with geodata and two with a phone number.
# Also write one with no geodata and no phone number.
# All five have summaries.
OpenGuides::Test->write_data( guide => $guide, node => "Page 1",
    summary => "A page", latitude => 51, longitude => 1, phone => "123",
    return_output => 1 );
OpenGuides::Test->write_data( guide => $guide, node => "Page 2",
    summary => "A page", latitude => 51.1, longitude => 1.1, phone => "456",
    return_output => 1 );
OpenGuides::Test->write_data( guide => $guide, node => "Page 3",
    summary => "A page", latitude => 51.2, longitude => 1.2,
    return_output => 1 );
OpenGuides::Test->write_data( guide => $guide, node => "Page 4",
    summary => "A page", latitude => 51.3, longitude => 1.3,
    return_output => 1 );
OpenGuides::Test->write_data( guide => $guide, node => "Page 5",
    summary => "A page", return_output => 1 );

# Note: map output is only enabled if Leaflet is enabled.

# Make sure the checkbox only appears if Leaflet is enabled.
$config->use_leaflet( 0 );
my $output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1 );
Test::HTML::Content::no_tag( $output, "input",
    { type => "checkbox", name => "format", value => "map" },
    "Map checkbox doesn't appear if Leaflet isn't enabled" );

$config->use_leaflet( 1 );
$output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1 );
Test::HTML::Content::tag_ok( $output, "input",
    { type => "checkbox", name => "format", value => "map" },
    "...but it does appear if it is" );

# If map is requested but Leaflet isn't enabled, there should be an apology.
$config->use_leaflet( 0 );
$output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1, metadata_type => "phone", format => "map" );
Test::HTML::Content::tag_ok( $output, "span",
    { class => "map_results_no_leaflet" },
    "span.map_results_no_leaflet appears if Leaflet's not enabled" );

$config->use_leaflet( 1 );
$output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1, metadata_type => "phone", format => "map" );
Test::HTML::Content::no_tag( $output, "span",
    { class => "map_results_no_leaflet" },
    "...but doesn't if it is" );

### All tests from here on are with Leaflet enabled.
$config->use_leaflet( 1 );

# Make sure that there's a message if nodes are returned but none of them
# have geodata.
$output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1, metadata_type => "latitude", format => "map" );
Test::HTML::Content::tag_ok( $output, "p", { class => "no_nodes_on_map" },
    "p.no_nodes_on_map appears if no returned nodes have geodata" );

# Make sure the map does show up properly if we have nodes with geodata.
# Pages 3 & 4 have geodata but no phone; Page 5 has neither phone nor geodata.
$output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1, metadata_type => "phone", format => "map" );
like( $output, qr/page\s+5\s+\(not\s+on\s+map/i,
      "when map shown, pages with no geodata are marked 'not on map'" );
Test::HTML::Content::link_ok( $output, "?Page_5", "...and are linked to" );
unlike( $output, qr/page\s+4\s+\(not\s+on\s+map/i,
        "pages with geodata are _not_ marked 'not on map'" );
like( $output, qr/param:[\s"]*Page_4/, "...and are included in JavaScript" );

# Navbar shouldn't appear if map does.
Test::HTML::Content::no_tag( $output, "div", { id => "navbar" },
    "navbar doesn't appear when map shows" );
Test::HTML::Content::no_tag( $output, "div", { id => "maincontent" },
    "...and no div#maincontent" );
Test::HTML::Content::tag_ok( $output, "div", { id => "maincontent_no_navbar" },
    "...we get div#maincontent_no_navbar instead" );

# But it should be there when we're listing instead of mapping.
$output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1, metadata_type => "phone" );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
    "navbar shown when no map" );
Test::HTML::Content::tag_ok( $output, "div", { id => "maincontent" },
    "...div#maincontent too" );
Test::HTML::Content::no_tag( $output, "div", { id => "maincontent_no_navbar" },
    "...but no div#maincontent_no_navbar" );

# It should also be there if we get no results from our search.
$output = $guide->show_missing_metadata( return_output => 1,
    noheaders => 1, metadata_type => "summary", format => "map" );
Test::HTML::Content::tag_ok( $output, "div", { id => "navbar" },
    "navbar shown when no search results" );
Test::HTML::Content::tag_ok( $output, "div", { id => "maincontent" },
    "...div#maincontent too" );
Test::HTML::Content::no_tag( $output, "div", { id => "maincontent_no_navbar" },
    "...but no div#maincontent_no_navbar" );
