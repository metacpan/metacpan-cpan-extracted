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

plan tests => 6;

# Clear out the database from any previous runs.

    OpenGuides::Test::refresh_db();

# Now we can start testing
my $config = OpenGuides::Test->make_basic_config;
$config->force_wgs84 (1);

my $guide = OpenGuides->new( config => $config );

my ($longitude, $latitude) = (10, 12);

my ($wgs_long, $wgs_lat) = OpenGuides::Utils->get_wgs84_coords(
                                                    longitude => $longitude,
                                                    latitude => $latitude,
                                                    config => $config);

is( $wgs_long, $longitude,
    "get_wgs84_coords returns the original longitude when force_wgs84 is on");
is( $wgs_lat, $latitude,
    "get_wgs84_coords returns the original latitude when force_wgs84 is on");


# Now claim to be in the UK
eval{ require Geo::HelmertTransform; };
my $have_helmert = $@ ? 0 : 1;
SKIP : {
    skip "Geo::HelmertTransform not installed - can't do transforms", 4
        unless $have_helmert;

    $config->force_wgs84(0);
    $config->geo_handler(1);

    # Set our location to be somewhere known
       ($longitude,$latitude)  = (-1.258200,51.754349);
    my ($wgs84_lon,$wgs84_lat) = (-1.259687,51.754813);

    ($wgs_long, $wgs_lat) = OpenGuides::Utils->get_wgs84_coords(
                                                     longitude => $longitude,
                                                     latitude => $latitude,
                                                     config => $config);

    # Round to 5 dp
    my $fivedp = 1 * 1000 * 100;
    $wgs_long = int($wgs_long * $fivedp)/$fivedp;
    $wgs_lat  = int($wgs_lat  * $fivedp)/$fivedp;
    $wgs84_lon = int($wgs84_lon * $fivedp)/$fivedp;
    $wgs84_lat = int($wgs84_lat * $fivedp)/$fivedp;

    is( $wgs_long, $wgs84_lon,
        "get_wgs84_coords does Airy1830 -> WGS84 convertion properly");
    is( $wgs_lat, $wgs84_lat,
        "get_wgs84_coords does Airy1830 -> WGS84 convertion properly");

    # Call it again, check we get the same result
    ($wgs_long, $wgs_lat) = OpenGuides::Utils->get_wgs84_coords(
                                                     longitude => $longitude,
                                                     latitude => $latitude,
                                                     config => $config);
    $wgs_long = int($wgs_long * $fivedp)/$fivedp;
    $wgs_lat  = int($wgs_lat  * $fivedp)/$fivedp;
    is( $wgs_long, $wgs84_lon,
        "get_wgs84_coords does Airy1830 -> WGS84 convertion properly");
    is( $wgs_lat, $wgs84_lat,
        "get_wgs84_coords does Airy1830 -> WGS84 convertion properly");
}
