use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

my $have_lucy = eval { require Lucy; } ? 1 : 0;
my $have_plucene = eval { require Plucene; } ? 1 : 0;
unless ( $have_lucy || $have_plucene ) {
    plan skip_all => "Neither Lucy nor Plucene is installed";
}

eval { require Test::HTML::Content; };
if ( $@ ) {
    plan skip_all => "Test::HTML::Content not installed";
}

plan tests => 12;

# Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

my $config = OpenGuides::Test->make_basic_config;
if ( $have_lucy ) {
  $config->use_lucy ( 1 );
} else {
  $config->use_plucene( 1 );
}

# British National Grid guides should have os_x/os_y/os_dist search fields.
my $guide = OpenGuides->new( config => $config );

OpenGuides::Test->write_data(
                              guide => $guide,
                              node  => "Banana Leaf",
                              os_x  => 532125,
                              os_y  => 165504,
                            );

# Display the node, check that the distance search form defaults to OS co-ords
# (stops places being "found" 70m away from themselves due to rounding).
my $output = $guide->display_node(
                                   id => "Banana Leaf",
                                   return_output => 1,
                                 );

# Strip Content-Type header to stop Test::HTML::Content getting confused.
$output =~ s/^Content-Type.*[\r\n]+//m;

Test::HTML::Content::tag_ok( $output, "select", { name => "os_dist" },
                             "distance select defaults to os_dist with BNG" );
# Use a regex; Test::HTML::Content can't do this yet I think (read docs, check)
like( $output, qr|select\sname="os_dist".*metres.*kilometres.*/select|is,
      "...and to offering distances in metres/kilometres" );
Test::HTML::Content::tag_ok( $output, "input",
                             { name => "os_x", value => "532125" },
                             "...includes input 'os_x' with correct value");
Test::HTML::Content::tag_ok( $output, "input",
                             { name => "os_y", value => "165504" },
                             "...includes input 'os_y' with correct value");


# Irish National Grid guides should have osie_x/osie_y/osie_dist.
$config->geo_handler( 2 );
$guide = OpenGuides->new( config => $config );

OpenGuides::Test->write_data(
                              guide  => $guide,
                              node   => "I Made This Place Up",
                              osie_x => 100000,
                              osie_y => 200000,
                            );

# Display node, check distance search form.
$output = $guide->display_node(
                                id => "I Made This Place Up",
                                return_output => 1,
                              );

$output =~ s/^Content-Type.*[\r\n]+//m;

Test::HTML::Content::tag_ok( $output, "select", { name => "osie_dist" },
                             "distance select defaults to osie_dist with ING");
like( $output, qr|select\sname="osie_dist".*metres.*kilometres.*/select|is,
      "...and to offering distances in metres/kilometres" );
Test::HTML::Content::tag_ok( $output, "input",
                             { name => "osie_x", value => "100000" },
                             "...includes input 'osie_x' with correct value");
Test::HTML::Content::tag_ok( $output, "input",
                             { name => "osie_y", value => "200000" },
                             "...includes input 'osie_y' with correct value");


# UTM guides should have latitude/longitude/latlong_dist.
$config->geo_handler( 3 );
$config->ellipsoid( "Airy" );
$guide = OpenGuides->new( config => $config );

OpenGuides::Test->write_data(
                              guide     => $guide,
                              node      => "London Aquarium",
                              latitude  => 51.502,
                              longitude => -0.118,
                            );

# Display node, check distance search form.
# UTM guides currently use latitude/longitude for searching.
$output = $guide->display_node(
                                id => "London Aquarium",
                                return_output => 1,
                              );
$output =~ s/^Content-Type.*[\r\n]+//m;

Test::HTML::Content::tag_ok( $output, "select", { name => "latlong_dist" },
                             "dist select defaults to latlong_dist with UTM" );
like( $output, qr|select\sname="latlong_dist".*metres.*kilometres.*/select|is,
      "...and to offering distances in metres/kilometres" );
Test::HTML::Content::tag_ok( $output, "input",
                             { name => "latitude", value => "51.502" },
                             "...includes input 'latitude' with correct value");
Test::HTML::Content::tag_ok( $output, "input",
                             { name => "longitude", value => "-0.118" },
                             "...includes input 'longitude' with correct value");
