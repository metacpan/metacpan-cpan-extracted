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

my $num_tests = 10;

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

    # Write some data.
    my $wiki = $search->{wiki};
    $wiki->write_node( "Wandsworth Common", "A common.", undef,
                       { category => "Parks" } )
        or die "Can't write node";
    $wiki->write_node( "Hammersmith", "A page about Hammersmith." )
        or die "Can't write node";

    # Check that the search forgets input search term between invocations.
    $search->run(
                  return_output => 1,
                  vars          => { search => "parks" },
                );
    ok( $search->{search_string}, "search_string set" );
    $search->run(
                  return_output => 1,
                );
    ok( !$search->{search_string}, "...and forgotten" );

    # Sanity check.
    my (@results, %tt_vars);
    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "parks" },
                           );
    @results = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@results, [ "Wandsworth Common" ],
               "first search returns expected results" );
    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "hammersmith" },
                           );
    @results = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@results, [ "Hammersmith" ],
               "so does second" );

    # Check that the search forgets input geodata between invocations.
    # First with British National Grid.
    $search->run(
                  return_output => 1,
                  vars => { os_x => 500000, os_y => 100000, os_dist => 1000 },
                );
    ok( $search->{x}, "x-coord set" );
    $search->run(
                  return_output => 1,
                  vars => { search => "foo" },
                );
    ok( !$search->{x}, "...and forgotten" );

    # Now with Irish National Grid.
    $config->geo_handler( 2 );
    $search = OpenGuides::Search->new( config => $config );
    $search->run(
                  return_output => 1,
                  vars => { osie_x => 100000, osie_y => 200000,
                            osie_dist => 100 },
                );
    ok( $search->{x}, "x-coord set" );
    $search->run(
                  return_output => 1,
                  vars => { search => "foo" },
                );
    ok( !$search->{x}, "...and forgotten" );

    # Now with UTM.
    $config->geo_handler( 3 );
    $config->ellipsoid( "Airy" );
    $search = OpenGuides::Search->new( config => $config );
    $search->run(
                  return_output => 1,
                  vars => { latitude => 10, longitude => 0,
                            latlong_dist => 1000 },
                );
    ok( $search->{x}, "x-coord set" );
    $search->run(
                  return_output => 1,
                  vars => { search => "foo" },
                );
    ok( !$search->{x}, "...and forgotten" );
}
