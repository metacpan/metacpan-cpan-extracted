use strict;
use Test::More tests => 13;

use Search::InvertedIndex;
use Search::InvertedIndex::DB::Pg;

SKIP: {
    skip "Test database not configured", 13 unless -e "test.conf";

    require Config::Tiny;
    my $conf_ref = Config::Tiny->read( "test.conf" );
    my %conf = %{ $conf_ref->{_} };

    my $db = Search::InvertedIndex::DB::Pg->new(
        -db_name    => $conf{dbname},
        -hostname   => $conf{dbhost},
        -port       => $conf{dbport},
        -username   => $conf{dbuser},
        -password   => $conf{dbpass},
        -table_name => "siindex",
        -lock_mode  => "EX",
    );

    # Get the database object, open the map.
    my $map  = Search::InvertedIndex->new( -database => $db );

    # Avoid interference from other tests which may not have cleaned up
    $map->clear_all;

    $map->add_group( -group => "test" );

    my ( $update, $query_leaf, $query, $result );

    # nonexistent group test
    $update = Search::InvertedIndex::Update->new( -group => "idonotexist",
                                                  -index => "nonexistent",
                                                  -data  => "nonexistent",
                                                  -keys  => {nonexistent => 1}
    );
    eval { $map->update( -update => $update ); };
    ok( $@, "update dies if group doesn't exist" );

    # existing group test
    $update = Search::InvertedIndex::Update->new( -group => "test",
                                                  -index => "test001",
                                                  -data  => "data001",
                                                  -keys  => { foo => 1,
                                                              bar => 1  } );
    isa_ok( $update, "Search::InvertedIndex::Update" );
    eval { $map->update( -update => $update ); };
    is( $@, "", "update doesn't die if group exists" );

    # checking that keys go in right
    $update = Search::InvertedIndex::Update->new( -group => "test",
                                                  -index => "test002",
                                                  -data  => "data002",
                                                  -keys  => { foo => 1,
                                                              baz => 1  } );
    $map->update( -update => $update );

    $query_leaf = Search::InvertedIndex::Query::Leaf->new( -key   => "foo",
                                                           -group => "test" );
    $query = Search::InvertedIndex::Query->new( -leafs => [ $query_leaf ] );
    $result = $map->search( -query => $query );
    ok( $result->number_of_index_entries, "can index a key" );
    is( $result->number_of_index_entries, 2, "...the right number of times" );

    $query_leaf = Search::InvertedIndex::Query::Leaf->new( -key => "quux",
                                                           -group => "test" );
    $query = Search::InvertedIndex::Query->new( -leafs => [ $query_leaf ] );
    $result = $map->search( -query => $query );
    is( $result->number_of_index_entries, 0, "...nonexistent keys not indexed" );

    # new index no data
    $update = Search::InvertedIndex::Update->new( -group => "test",
                                                  -index => "test003",
                                                  -keys  => { foo => 1,
                                                              bar => 1  } );
    isa_ok( $update, "Search::InvertedIndex::Update" );
    eval { $map->update( -update => $update ); };
    ok( $@, "update dies when -index is new but no -data passed" );

    # check updating on an old index
    #  - with no supplied -data
    $update = Search::InvertedIndex::Update->new( -group => "test",
                                                  -index => "test001",
                                                  -keys  => { grault => 1 } );
    eval { $map->update( -update => $update ); };
    is( $@, "", "update with no -data doesn't die if -index is preexisting" );

    $query_leaf = Search::InvertedIndex::Query::Leaf->new( -key   => "bar",
                                                           -group => "test" );
    $query = Search::InvertedIndex::Query->new( -leafs => [ $query_leaf ] );
    $result = $map->search( -query => $query );
    is( $result->number_of_index_entries, 0, "...old keys were removed" );

    $query_leaf = Search::InvertedIndex::Query::Leaf->new( -key   => "grault",
                                                           -group => "test" );
    $query = Search::InvertedIndex::Query->new( -leafs => [ $query_leaf ] );
    $result = $map->search( -query => $query );
    is( $result->number_of_index_entries, 1, "...and new ones added" );
    my ( $index, $data, $ranking ) = $result->entry( -number => 0 );
    is( $data, "data001", "...and data is left untouched" );

    #  -with new supplied -data
    $update = Search::InvertedIndex::Update->new( -group => "test",
                                                  -index => "test001",
                                                  -data  => "newdata",
                                                  -keys  => { grault => 1 } );
    $map->update( -update => $update );
    $query_leaf = Search::InvertedIndex::Query::Leaf->new( -key   => "grault",
                                                           -group => "test" );
    $query = Search::InvertedIndex::Query->new( -leafs => [ $query_leaf ] );
    $result = $map->search( -query => $query );
    ($index, $data, $ranking) = $result->entry( -number => 0 );
    is( $data, "newdata",
        "data is updated when -data passed to update on old index" );

}
    