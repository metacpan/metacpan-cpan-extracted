use strict;
use Test::More tests => 7;

use Search::InvertedIndex;
use Search::InvertedIndex::DB::Pg;

SKIP: {
    skip "Test database not configured", 7 unless -e "test.conf";

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

    # Check that there are no keys in the system.
    is( $map->number_of_keys, 0, "cleared system has no keys" );

    # Create a test group
    my $group = 'test';
    $map->add_group( -group => $group );

    # Check that there are no keys in the group.
    is( $map->number_of_keys_in_group( -group => $group ), 0,
        "system with newly-added group has no ekeys" );

    # Explicitly add a list of keys
    my (@test_keys) = qw( blah hello whaah! );
    foreach my $key (@test_keys) {
        $map->add_key_to_group( -group => $group, -key => $key );
    }

    # Check that we get back what we inserted
    is( $map->number_of_keys_in_group( -group => $group ), scalar @test_keys,
        "keys can be added to group" );

    my $keys = $map->list_all_keys_in_group( -group => $group );
    is_deeply( [ sort @$keys ], [ sort @test_keys ],
               "...and retrieved" );

    # Test deleting keys one by one.
    my $i = 0;
    foreach my $key ( reverse @test_keys ) {
        is( $map->first_key_in_group( -group => $group ), $key,
            "first key is $key after $i deletions" );
        $map->remove_key_from_group( -group => $group, -key => $key );
        $i++;
      }

    # Clean up to avoid interfering with other tests.
    $map->clear_all;
}

