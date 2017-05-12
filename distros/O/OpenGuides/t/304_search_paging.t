use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with ($error)";
}

my $have_lucy = eval { require Lucy; } ? 1 : 0;
my $have_plucene = eval { require Plucene; } ? 1 : 0;

my $num_tests = 18;

plan tests => $num_tests * 2;

SKIP: {
    skip "Plucene not installed.", $num_tests unless $have_plucene;
    run_tests();
}

SKIP: {
    skip "Lucy not installed.", $num_tests unless $have_lucy;
    run_tests( use_lucy => 1 );
}

sub run_tests {
    my %args = @_;

    # Clear out the database from any previous runs.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;

    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        $config->use_plucene( 1 );
    }

    my $search = OpenGuides::Search->new( config => $config );
    my $guide = OpenGuides->new( config => $config );

    # Test with OS co-ords.
    $config->geo_handler( 1 );

    foreach my $i ( 1 .. 50 ) {
        OpenGuides::Test->write_data(
                                      guide          => $guide,
                                      node           => "Crabtree Tavern $i",
                                      os_x           => 523465,
                                      os_y           => 177490,
                                      categories     => "Pubs",
                                      return_output => 1,
                                    );
    }

    my $output = $search->run(
                               return_output => 1,
                               vars          => {
                                                  os_dist => 1500,
                                                  os_x => 523500,
                                                  os_y => 177500,
                                                  next => 21,
                                                },
                             );
    like( $output, qr/search.cgi\?.*os_x=523500.*Next.*results/s,
          "os_x retained in next page link" );
    like( $output, qr/search.cgi\?.*os_y=177500.*Next.*results/s,
          "os_y retained in next page link" );
    like( $output, qr/search.cgi\?.*os_dist=1500.*Next.*results/s,
          "os_dist retained in next page link" );
    like( $output, qr/search.cgi\?.*os_x=523500.*Previous.*results/s,
          "os_x retained in previous page link" );
    like( $output, qr/search.cgi\?.*os_y=177500.*Previous.*results/s,
          "os_y retained in previous page link" );
    like( $output, qr/search.cgi\?.*os_dist=1500.*Previous.*results/s,
          "os_dist retained in previous page link" );

    # Test with OSIE co-ords.

    # We must create a new search object after changing the geo_handler
    # in order to force it to create a fresh locator.
    $config->geo_handler( 2 );
    $search = OpenGuides::Search->new( config => $config );

    foreach my $i ( 1 .. 50 ) {
        OpenGuides::Test->write_data(
                                      guide      => $guide,
                                      node       => "I Made This Place Up $i",
                                      osie_x     => 100005,
                                      osie_y     => 200005,
                                      return_output => 1,
                                    );
    }

    $output = $search->run(
                               return_output => 1,
                               vars          => {
                                                  osie_dist => 1500,
                                                  osie_x => 100000,
                                                  osie_y => 200000,
                                                  next => 21,
                                                },
                             );
    like( $output, qr/search.cgi\?.*osie_x=100000.*Next.*results/s,
          "osie_x retained in next page link" );
    like( $output, qr/search.cgi\?.*osie_y=200000.*Next.*results/s,
          "osie_y retained in next page link" );
    like( $output, qr/search.cgi\?.*osie_dist=1500.*Next.*results/s,
          "osie_dist retained in next page link" );
    like( $output, qr/search.cgi\?.*osie_x=100000.*Previous.*results/s,
          "osie_x retained in previous page link" );
    like( $output, qr/search.cgi\?.*osie_y=200000.*Previous.*results/s,
          "osie_y retained in previous page link" );
    like( $output, qr/search.cgi\?.*osie_dist=1500.*Previous.*results/s,
          "osie_dist retained in previous page link" );

    # Test with UTM.

    # We must create a new search object after changing the geo_handler
    # in order to force it to create a fresh locator.
    $config->geo_handler( 3 );
    $search = OpenGuides::Search->new( config => $config );

    foreach my $i ( 1 .. 50 ) {
        OpenGuides::Test->write_data(
                                      guide      => $guide,
                                      node       => "London Aquarium $i",
                                      latitude   => 51.502,
                                      longitude  => -0.118,
                                      return_output => 1,
                                    );
    }

    $output = $search->run(
                               return_output => 1,
                               vars          => {
                                                  latlong_dist => 1500,
                                                  latitude     => 51.5,
                                                  longitude    => -0.12,
                                                  next         => 21,
                                                },
                             );
    like( $output, qr/search.cgi\?.*latitude=51.5.*Next.*results/s,
          "latitude retained in next page link" );
    like( $output, qr/search.cgi\?.*longitude=-0.12.*Next.*results/s,
          "longitude retained in next page link" );
    like( $output, qr/search.cgi\?.*latlong_dist=1500.*Next.*results/s,
          "latlong_dist retained in next page link" );
    like( $output, qr/search.cgi\?.*latitude=51.5.*Previous.*results/s,
          "latitude retained in previous page link" );
    like( $output, qr/search.cgi\?.*longitude=-0.12.*Previous.*results/s,
          "longitude retained in previous page link" );
    like( $output, qr/search.cgi\?.*latlong_dist=1500.*Previous.*results/s,
          "latlong_dist retained in previous page link" );
}
