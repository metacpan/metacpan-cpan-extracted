use strict;
use Wiki::Toolkit::Plugin::Locator::Grid; # use directly to help debug
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More;

eval { require DBD::SQLite; };
if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

my $have_lucy = eval { require Lucy; } ? 1 : 0;
my $have_plucene = eval { require Plucene; } ? 1 : 0;

my $num_tests = 9;

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
                     geo_handler        => 1,
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
                                  os_x          => 523465,
                                  os_y          => 177490,
                                  categories    => "Pubs",
                                  return_output => 1,
                                );

    OpenGuides::Test->write_data(
                                  guide         => $guide,
                                  node          => "Blue Anchor",
                                  os_x          => 522909,
                                  os_y          => 178232,
                                  categories    => "Pubs",
                                  return_output => 1,
                                );

    OpenGuides::Test->write_data(
                                  guide         => $guide,
                                  node          => "Star Tavern",
                                  os_x          => 528107,
                                  os_y          => 179347,
                                  categories    => "Pubs",
                                  return_output => 1,
                                );

    OpenGuides::Test->write_data(
                                  guide         => $guide,
                                  node          => "Hammersmith Bridge",
                                  os_x          => 522983,
                                  os_y          => 178118,
                                  return_output => 1,
                                );

    # Sanity check.
    print "# Distances should be:\n";
    my $locator = Wiki::Toolkit::Plugin::Locator::Grid->new(
                      x => "os_x", y => "os_y" );
    my $wiki = $guide->wiki;
    $wiki->register_plugin( plugin => $locator );
    foreach my $node ( "Blue Anchor", "Crabtree Tavern", "Hammersmith Bridge"){
        print "# $node: " . $locator->distance( from_x  => 523450,
                                                from_y  => 177650,
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
    my $output = $search->run(
                                return_output => 1,
                                vars => {
                                          latitude     => 51.484320,
                                          longitude    => -0.223484,
                                          latlong_dist => 1000,
                                        },
                              );
    unlike( $output, qr|(score:\s+)|, "...no spurious 'scores' printed" );

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
                                       os_x    => 523450,
                                       os_y    => 177650,
                                       os_dist => 1000,
                                       search  => " ",
                                     },
                           );
    @ordered = map { $_->{name} } @{ $tt_vars{results} || [] };
    @found = sort @ordered;
    is_deeply( \@found,
           [ "Blue Anchor", "Crabtree Tavern", "Hammersmith Bridge" ],
           "...works with OS co-ords" );

    %tt_vars = eval {
           $search->run(
                         return_tt_vars => 1,
                         vars => {
                                   os_x      => 523450,
                                   os_y      => 177650,
                                   os_dist   => 1000,
                                   search    => " ",
                                   latitude  => " ",
                                   longitude => " ",
                                 },
                       );
    };
    is( $@, "", "...works with OS co-ords and whitespace-only lat/long" );
    @ordered = map { $_->{name} } @{ $tt_vars{results} || [] };
    @found = sort @ordered;
    is_deeply( \@found,
           [ "Blue Anchor", "Crabtree Tavern", "Hammersmith Bridge" ],
             "...returns the right stuff" );

    %tt_vars = $search->run(
                         return_tt_vars    => 1,
                         vars    => {
                                   latitude     => 51.484320,
                                   longitude    => -0.223484,
                                   latlong_dist => 1000,
                                   search       => "pubs",
                                 },
                       );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Blue Anchor", "Crabtree Tavern", ],
           "distance search in combination with text search works" );

    %tt_vars = $search->run(
                         return_tt_vars    => 1,
                         vars    => {
                                   os_x    => 523450,
                                   os_y    => 177650,
                                   os_dist => 1000,
                                   search  => "pubs",
                                 },
                       );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Blue Anchor", "Crabtree Tavern", ],
           "...works with OS co-ords too" );
}
