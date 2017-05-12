use strict;
use Test::More tests => 6;

use Search::InvertedIndex;
use Search::InvertedIndex::DB::Pg;

SKIP: {
    skip "Test database not configured", 6 unless -e "test.conf";

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

    # Check that there are no indexes in the system.
    is( $map->number_of_indexes, 0, "cleared system has no indexes" );

    # Explicitly add a list of indexes
    my (@test_indexes) = qw( blah hello whaah! );
    foreach my $index (@test_indexes) {
        $map->add_index( -index => $index, -data => {} );
    }

    # Check that we get back what we inserted
    is( $map->number_of_indexes, scalar @test_indexes,
        "indexes can be added to map" );

    my $indexes = $map->list_all_indexes;
    is_deeply( [ sort @$indexes ], [ sort @test_indexes ],
               "...and retrieved" );

    # Test deleting indexes one by one.
    my $i = 0;
    foreach my $index ( reverse @test_indexes ) {
        is( $map->first_index, $index,
            "first index is $index after $i deletions" );
        $map->remove_index_from_all( -index => $index );
        $i++;
      }

    # Clean up to avoid interfering with other tests.
    $map->clear_all;
}

