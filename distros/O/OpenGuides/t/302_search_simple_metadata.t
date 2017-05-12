use strict;
use Wiki::Toolkit::Setup::SQLite;
use OpenGuides::Config;
use OpenGuides::Search;
use OpenGuides::Test;
use Test::More tests => 20;

eval { require DBD::SQLite; };

if ( $@ ) {
    my ($error) = $@ =~ /^(.*?)\n/;
    plan skip_all => "DBD::SQLite could not be used - no database to test with. ($error)";
}

run_tests();

my $have_lucy = eval { require Lucy; } ? 1 : 0;

SKIP: {
    skip "Lucy not installed.", 10 unless $have_lucy;
    run_tests( use_lucy => 1 );
}

sub run_tests {
    my %args = @_;

    # Clear out the database.
    OpenGuides::Test::refresh_db();

    my $config = OpenGuides::Test->make_basic_config;
    if ( $args{use_lucy} ) {
        $config->use_lucy( 1 );
        $config->use_plucene( 0 );
    } else {
        # Plucene is recommended over Search::InvertedIndex.
        eval { require Wiki::Toolkit::Search::Plucene; };
        if ( $@ ) { $config->use_plucene( 0 ) };
    }

    my $search = OpenGuides::Search->new( config => $config );

    # Add some data.  We write it twice to avoid hitting the redirect.
    my $wiki = $search->{wiki}; # white boxiness
    $wiki->write_node( "Calthorpe Arms", "Serves beer.", undef,
                       { category => "Pubs", locale => "Holborn" } );
    $wiki->write_node( "Penderel's Oak", "Serves beer.", undef,
                       { category => "Pubs", locale => "Holborn" } );
    $wiki->write_node( "British Museum", "Huge museum, lots of artifacts.",
                       undef,
                       { category => ["Museums", "Major Attractions"]
                       , locale => ["Holborn", "Bloomsbury"] } );

    # Check that a search on its category works.
    my %tt_vars = $search->run(
                                return_tt_vars => 1,
                                vars           => { search => "Pubs" },
                              );
    my @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Calthorpe Arms", "Penderel's Oak" ],
               "simple search looks in category" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "pubs" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Calthorpe Arms", "Penderel's Oak" ],
               "...and is case-insensitive" );

    # Check that a search on its locale works.
    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "Holborn" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found,
               [ "British Museum", "Calthorpe Arms", "Penderel's Oak" ],
               "simple search looks in locale" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "holborn" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found,
               [ "British Museum", "Calthorpe Arms", "Penderel's Oak" ],
               "...and is case-insensitive" );

    # Test AND search in various combinations.
    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "Holborn Pubs" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Calthorpe Arms", "Penderel's Oak" ],
               "AND search works between category and locale" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars         => { search => "Holborn Penderel" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Penderel's Oak" ],
               "AND search works between title and locale" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "Pubs Penderel" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Penderel's Oak" ],
               "AND search works between title and category" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "Holborn beer" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Calthorpe Arms", "Penderel's Oak" ],
               "...and between body and locale" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars           => { search => "Pubs beer" },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "Calthorpe Arms", "Penderel's Oak" ],
               "...and between body and category" );

    %tt_vars = $search->run(
                             return_tt_vars => 1,
                             vars => { search => '"major attractions"' },
                           );
    @found = sort map { $_->{name} } @{ $tt_vars{results} || [] };
    is_deeply( \@found, [ "British Museum", ],
               "Multi word category name" );
}
