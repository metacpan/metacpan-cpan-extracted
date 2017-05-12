use strict;
use OpenGuides;
use OpenGuides::CGI;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all =>
        "DBD::SQLite could not be used - no database to test with. ($error)";
}

eval { require Test::HTML::Content; };
my $thc = $@ ? 0 : 1;

plan tests => 25;

# Clear out the database from any previous runs.
OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
$config->static_url( "http://example.com/static" );
my $guide = OpenGuides->new( config => $config );
my $wiki = $guide->wiki;

# Write a couple of nodes, two with legitimate geodata, another with
# broken geodata, another with no geodata.
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Red Lion",
                              address       => "High Street",
                              latitude      => 51.4,
                              longitude     => -0.2,
                              locales       => "Croydon\r\nWaddon",
                              return_output => 1,
                            );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Blue Lion",
                              latitude      => 51.6,
                              longitude     => 0.6,
                              locales       => "Croydon",
                              return_output => 1,
                            );

# We have to write this one using Wiki::Toolkit, since OpenGuides now has
# checks for bad geodata - but we still want to test it, since someone might
# have old data in their database.
$wiki->write_node( "Broken Lion", "Here is some content.", undef, {
                       latitude  => "51d 32m 31.94s",
                       longitude => "0d 0m 8.23s",
                       locale    => "Croydon"
                   } )
  or die "Can't write node.";

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Lost Lion",
                              locales       => "Croydon\r\nAddiscombe",
                              return_output => 1,
                            );

# Make sure we include the GMaps JavaScript if we're not using Leaflet and
# we've included an API key.
$config->use_leaflet( 0 );
$config->gmaps_api_key( "I like using deprecated code" );

my $output = $guide->display_node( id => "Red Lion", return_output => 1 );
like( $output, qr/<script.*I like using deprecated code/,
      "GMaps JavaScript included when Leaflet switched off and GMaps API key "
      . "supplied." );

# Conversely, if we are using Leaflet then we need its JS but not GMaps', and
# we also need our own.
$config->use_leaflet( 1 );
$output = $guide->display_node( id => "Red Lion", return_output => 1 );
unlike( $output, qr/<script.*I like using deprecated code/,
        "...but not when Leaflet switched on." );
like( $output, qr|http://cdn.leafletjs.com/.*leaflet.js|,
      "Leaflet JavaScript is included when Leaflet switched on." );
like( $output, qr|http://example.com/static/map-leaflet.js|,
      "...as is our own Leaflet map JavaScript." );

# Make sure the map doesn't try to show nodes with missing or broken geodata.
my %tt_vars = $guide->show_index( loc => "Croydon",
                                  format => "map", return_tt_vars => 1 );
my @nodes = @{$tt_vars{nodes}};
is( scalar @nodes, 4, "Right number of nodes in TT variables." );
my %node_hash = map { $_->{name} => $_ } @nodes;
ok( !$node_hash{"Broken Lion"}{has_geodata},
    "Nodes with broken geodata don't have has_geodata set." );
ok( !$node_hash{"Lost Lion"}{has_geodata},
    "Nodes with no geodata don't have has_geodata set." );

# And check again in the HTML, in case of template bugs.
$output = $guide->show_index( loc => "Croydon",
                              format => "map", return_output => 1 );
unlike( $output, qr|name:\s*Lost\s+Lion|,
        "Nodes with no geodata are not passed to JavaScript object." );

# Check geodata variables for nodes that do have such data.
ok( $node_hash{"Red Lion"}{has_geodata},
    "Nodes with geodata have has_geodata set" );
ok( $node_hash{"Red Lion"}{wgs84_lat},
    "Nodes with geodata have wgs84_lat set" );
ok( $node_hash{"Red Lion"}{wgs84_long},
    "Nodes with geodata have wgs84_long set" );

# Make sure the centre of the map is set properly.
is( $tt_vars{centre_lat}, 51.5, "centre_lat set correctly" );
is( $tt_vars{centre_long}, 0.2, "centre_long set correctly" );

# Make sure name and address are passed through to the JavaScript for adding
# markers to the map.
$output = $guide->show_index( loc => "Waddon",
                              format => "map", return_output => 1 );
like( $output, qr/name:\s*["']Red\s+Lion["']/,
      "Name added to JavaScript object." );
like( $output, qr/address:\s*["']High\s+Street["']/,
      "Address added to JavaScript object." );

# Make sure nodes with no geodata get linked to despite not being on the map.
$output = $guide->show_index( loc => "Addiscombe",
                              format => "map", return_output => 1 );
like( $output, qr|Lost_Lion|, "Nodes with no geodata still get linked." );

# Make sure nodes with zero lat or long still have has_geodata set.
OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Zero Lat",
                              latitude      => 0,
                              longitude     => -0.2,
                              locales       => "Zero Land",
                              categories    => "Numerical Nodes",
                              return_output => 1,
                            );

OpenGuides::Test->write_data(
                              guide         => $guide,
                              node          => "Zero Long",
                              latitude      => 51.6,
                              longitude     => 0,
                              locales       => "Zero Land",
                              return_output => 1,
                            );

%tt_vars = $guide->show_index( loc => "Zero Land",
                               format => "map", return_tt_vars => 1 );
@nodes = @{$tt_vars{nodes}};
%node_hash = map { $_->{name} => $_ } @nodes;
ok( $node_hash{"Zero Lat"}{has_geodata},
    "Nodes with zero latitude have has_geodata set." );
ok( $node_hash{"Zero Long"}{has_geodata},
    "Nodes with zero longitude have has_geodata set." );

# Check capitalisation.
$output = $guide->show_index( cat => "numerical nodes",
                               format => "map", return_output => 1 );
like( $output, qr/Category\s+Numerical\s+Nodes/,
      "Multi-word categories are capitalised properly." );
$output = $guide->show_index( loc => "zero land",
                               format => "map", return_output => 1 );
like( $output, qr/Locale\s+Zero\s+Land/,
      "Multi-word locales are capitalised properly." );

# Map shouldn't be displayed if none of the nodes have geodata.
%tt_vars = $guide->show_index( loc => "Addiscombe",
                               format => "map", return_tt_vars => 1 );
ok( $tt_vars{no_nodes_on_map},
    "no_nodes_on_map template variable is set when no nodes have geodata" );
$output = $guide->show_index( loc => "Addiscombe",
                              format => "map", return_output => 1 );
unlike( $output, qr/not on map/,
        "...and no warning about individual things not being on the map" );
unlike( $output, qr/centre_lat/,
        "...and no attempt to set centre_lat JavaScript variable" );

# Check titles when showing map of everything.
$output = $guide->show_index( format => "map", noheaders => 1,
                              return_output => 1 );
SKIP: {
    skip "Test::HTML::Content not available", 1 unless $thc;
    Test::HTML::Content::tag_ok( $output, 'title', {}, qr/Map of all nodes/,
       "<title> correct when showing map of everything" );
}
like( $output, qr/<h2 class="map_index_header">Map\s+of\s+all\s+nodes/, "...as is <h2> title" );
