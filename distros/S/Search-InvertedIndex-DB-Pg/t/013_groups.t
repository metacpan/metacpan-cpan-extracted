use strict;
use Test::More tests => 10;

use Search::InvertedIndex;
use Search::InvertedIndex::DB::Pg;

SKIP: {
    skip "Test database not configured", 10 unless -e "test.conf";

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

    # Check that there are no groups in the system.
    my $groups = $map->list_all_groups;
    is( scalar @$groups, 0,
        "list_all_groups finds no groups in cleared system" );
    is( $map->number_of_groups, 0, "...neither does number_of_groups" );

    # Explictly add some groups
    my @test_groups = qw( able baker charlie delta );
    foreach my $group ( @test_groups ) {
  	    $map->add_group( -group => $group );
    }

    # Check that we get back what we inserted.
    $groups = $map->list_all_groups;
    is_deeply( [ sort @$groups ], [ sort @test_groups ],
    	   "can get back groups we just added" );

    # Check that a newly-added group has no indexes.
    is( $map->number_of_indexes_in_group( -group => $test_groups[0] ), 0,
        "newly-added group has no indexes" );

    # Check that deletion of a nonexistent index has no side-effects.
    $map->remove_index_from_all( -index => "no such animal" );
    is( $map->number_of_indexes_in_group( -group => $test_groups[0] ), 0,
        "...index count still zero after deleting nonexistent index" );

    # Check no groups remain after clearing database.
    $map->clear_all;
    $groups = $map->list_all_groups;
    is( scalar @$groups, 0, "no groups remain after clear_all" );

    # Test deleting groups one by one.
    foreach my $group ( @test_groups ) {
  	    $map->add_group( -group => $group );
    }
    my $i = 0;
    foreach my $group ( reverse @test_groups ) {
        is( $map->first_group, $group,
            "first group is $group after $i deletions" );
        $map->remove_group( -group => $group );
        $i++;
      }

    # Clean up to avoid interfering with other tests.
    $map->clear_all;
}

