use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More tests => 32;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

run_tests();

my $have_lucy = eval { require Lucy; } ? 1 : 0;

SKIP: {
    skip "Lucy not installed.", 16 unless $have_lucy;
    run_tests( use_lucy => 1 );
}

sub run_tests {
    my %args = @_;

    # Clear out the database.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;
    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
    }
    my $guide = OpenGuides->new( config => $config );
    my $search = OpenGuides::Search->new( config => $config );

    my %results;

    %results = $search->run( vars => { format => "raw" } );
    is_deeply( \%results, { },
           "raw search returns empty hash if no criteria supplied" );
    %results = $search->run( vars => { search => "banananana",
                             format => "raw" } );
    is_deeply( \%results, { },
           "raw search returns empty hash if no hits on search string" );

    # Pop some data in and search again.
    OpenGuides::Test->write_data( guide => $guide,
                                  node  => "Red Lion",
                                  content => "A nice pub in Anyville.",
                                  summary => "Nice pub.",
                                  os_x => 500000,
                                  os_y => 150000,
                                  return_output => 1,
                                );
    OpenGuides::Test->write_data( guide => $guide,
                                  node  => "Blacksmiths Arms",
                                  content => "Not a very nice pub.",
                                  summary => "Rubbish pub.",
                                  os_x => 500100,
                                  os_y => 150000,
                                  return_output => 1,
                                );
    OpenGuides::Test->write_data( guide => $guide,
                                  node  => "Carpenters Arms",
                                  content => "Not a bad pub.",
                                  summary => "Average pub.",
                                  os_x => 450000,
                                  os_y => 140000,
                                  return_output => 1,
                                );

    %results = $search->run( vars => { search => "arms", format => "raw" } );
    is_deeply( [ sort keys %results ],
               [ "Blacksmiths Arms", "Carpenters Arms" ],
               "raw search on single word finds the right nodes" );
    my %ba = %{$results{"Blacksmiths Arms"}};
    is( $ba{name}, "Blacksmiths Arms", "result hash has correct name" );
    is( $ba{summary}, "Rubbish pub.", "...and correct summary" );
    ok( $ba{wgs84_long}, "...WGS-84 latitude returned" );
    ok( $ba{wgs84_lat}, "...WGS-84 longitude returned" );
    ok( $ba{score}, "...score returned" );
    ok( !$ba{distance}, "...no distance returned" );

    # Now try a distance search.
    %results = $search->run(
                             vars => {
                                       os_dist => 1000,
                                       os_x    => 500200,
                                       os_y    => 150000,
                                       format  => "raw",
                                     } );
    is_deeply( [ sort keys %results ], [ "Blacksmiths Arms", "Red Lion" ],
               "raw distance search finds the right nodes" );
    my %rl = %{$results{"Red Lion"}};
    is( $rl{name}, "Red Lion", "result hash has correct name" );
    is( $rl{summary}, "Nice pub.", "...and correct summary" );
    ok( $rl{wgs84_lat}, "...WGS-84 latitude returned" );
    ok( $rl{wgs84_long}, "...WGS-84 longitude returned" );
    ok( !$rl{score}, "...no score returned" );
    is( $rl{distance}, 200, "...correct distance returned" );
}
