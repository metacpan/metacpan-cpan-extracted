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

my $num_tests = 4;

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

    my $config = OpenGuides::Config->new(
           vars => {
                     dbtype             => "sqlite",
                     dbname             => "t/node.db",
                     indexing_directory => "t/indexes",
                     script_name        => "wiki.cgi",
                     script_url         => "http://example.com/",
                     site_name          => "Test Site",
                     template_path      => "./templates",
                     geo_handler        => 3,
                     ellipsoid          => "Airy",
               }
    );

    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        $config->use_plucene( 1 );
    }

    my $search = OpenGuides::Search->new( config => $config );
    my $guide = OpenGuides->new( config => $config );

    # Write some data.
    OpenGuides::Test->write_data(
                                  guide         => $guide,
                                  node          => "Crabtree Tavern",
                                  latitude      => 51.482385,
                                  longitude     => -0.221743,
                                  categories    => "Pubs",
                                  return_output => 1,
                                );

    OpenGuides::Test->write_data(
                                  guide         => $guide,
                                  node          => "Blue Anchor",
                                  latitude      => 51.489176,
                                  longitude     => -0.229488,
                                  categories    => "Pubs",
                                  return_output => 1,
                                );

    OpenGuides::Test->write_data(
                                  guide         => $guide,
                                  node          => "Star Tavern",
                                  latitude      => 51.498043,
                                  longitude     => -0.154247,
                                  categories    => "Pubs",
                                  return_output => 1,
                                );

    OpenGuides::Test->write_data(
                                  guide         => $guide,
                                  node          => "Hammersmith Bridge",
                                  latitude      => 51.488135,
                                  longitude     => -0.228463,
                                  return_output => 1,
                                );

    # Sanity check.
    print "# Distances should be round about:\n";
    my $locator = $guide->locator;
    foreach my $node ( "Blue Anchor", "Crabtree Tavern", "Hammersmith Bridge"){
        print "# $node: " . $locator->distance( from_x  => 692756,
                                                from_y  => 5706917,
                                                to_node => $node ) . "\n";
    }

    # Check that a lat/long distance search finds them.
    my %tt_vars = $search->run(
                                return_tt_vars => 1,
                                vars => {
                                          latitude     => 51.484320,
                                          longitude    => -0.223484,
                                          latlong_dist => 1000,
                                        },
                              );
    my @ordered = map { $_->{name} } @{ $tt_vars{results} || [] };
    my @found = sort @ordered;
    is_deeply( \@found,
               [ "Blue Anchor", "Crabtree Tavern", "Hammersmith Bridge" ],
               "distance search finds the right things" );
    is_deeply( \@ordered,
               [ "Crabtree Tavern", "Hammersmith Bridge", "Blue Anchor" ],
               "...and returns them in the right order" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars => {
                                       latitude     => 51.484320,
                                       longitude    => -0.223484,
                                       latlong_dist => 1000,
                                       search       => " ",
                                     },
                           );
    @ordered = map { $_->{name} } @{ $tt_vars{results} || [] };
    @found = sort @ordered;
    is_deeply( \@found,
               [ "Blue Anchor", "Crabtree Tavern", "Hammersmith Bridge" ],
               "...still works if whitespace-only search text supplied" );

    %tt_vars = $search->run(
                         return_tt_vars => 1,
                         vars => {
                                   latitude     => 51.484320,
                                   longitude    => -0.223484,
                                   latlong_dist => 1000,
                                   search       => "pubs",
                                 },
                       );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Blue Anchor", "Crabtree Tavern", ],
           "distance search in combination with text search works" );
}
