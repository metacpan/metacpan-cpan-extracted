use strict;
use Test::More tests => 38;

use Search::InvertedIndex;
use Search::InvertedIndex::DB::Pg;

require "t/test.lib";

SKIP: {
    skip "Test database not configured", 38 unless -e "test.conf";

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

    # Add a test group
    my $group = 'test-group';
    $map->add_group( -group => $group );

    # Get a test dataset.  $test_set, @key_list and @index_list will
    # be accessed below a few times more.
    my $test_set = make_dataset(4, 4);
    my %key_counter;
    foreach my $index ( keys %$test_set ) {
        my %keys  = %{ $test_set->{$index}{ -keys } };
        foreach my $key ( keys %keys ) {
            $key_counter{$key}++;
          }
    }
    my @key_list   = keys %key_counter;
    my @index_list = keys %$test_set;
    die "No keys!"    unless scalar @key_list;
    die "No indexes!" unless scalar @index_list;
    print "# Generated test data has keys: " . join(" ", @key_list) . "\n";
    print "#   and indexes: " . join(" ", @index_list) . "\n";

    # Load in the test data.
    load_test_data( $map, $group, $test_set, \@index_list );

    # Check that there are the correct number of keys in the group.
    is( $map->number_of_keys_in_group( -group => $group ),
        scalar @key_list,
        "number_of_keys_in_group sees right no. of keys in new database" );

    # Check that we get back the keys that we inserted
    my $read_keys = $map->list_all_keys_in_group( -group => $group );
    print "# Returned keys: " . join(" ", @$read_keys) . "\n";
    is_deeply( [ sort @$read_keys ], [ sort @key_list ],
               "...and list_all_keys_in_group sees the right ones" );

    # Check that there are the correct number of indexes in the group.
    is( $map->number_of_indexes_in_group( -group => $group ),
        scalar @index_list,
        "number_of_indexes_in_group sees right no. of indexes in new db" );

    # Check that we get back the indexes that we inserted
    my $read_indexes = $map->list_all_indexes_in_group( -group => $group );
    print "# Found indexes: " . join(" ", @$read_indexes) . "\n";
    is_deeply( [ sort @$read_indexes ], [ sort @index_list ],
               "...and list_all_indexes_in_group sees the right ones" );

    # check that we can iterate over the indexes and delete
    # indexes from the group and get back *exactly* what we are supposed to
    for my $i ( 0 .. $#index_list ) {
        my $first_index = $map->first_index_in_group( -group => $group );
        print "# First index is now $first_index\n";
        is( $first_index, $index_list[$#index_list - $i],
            "first_index_in_group is correct after $i deletions" );

        my @remaining_indexes = ( $first_index );
        my $index = $first_index;
        my $next_index;
        while ( defined ( $next_index =
                  $map->next_index_in_group( -group => $group,
                                             -index => $index ) )
               ) {
            push @remaining_indexes, $next_index;
            $index = $next_index;
        }

        my @slice = @index_list[0 .. $#index_list - $i];
        # Reverse the slice since the indexes come out in the reverse
        # order to going in (ie, last index added is considered to be
        # the first index)
        @slice = reverse @slice;
        print "# Remaining indexes should be: " . join(" ", @slice) . "\n";
        print "# and in fact are: " . join(" ", @remaining_indexes) . "\n";
        is_deeply( \@remaining_indexes, \@slice,
                   "...next_index_in_group works for remaining indexes" );

        ok( $map->remove_index_from_group( -group => $group,
                                           -index => $first_index ),
            "removed index from group" );
    }

    # Reload the test data.
    $map->clear_all;
    $map->add_group( -group => $group );
    load_test_data( $map, $group, $test_set, \@index_list );

    # Check that there are the correct number of indexes in the system.
    is( $map->number_of_indexes,
        scalar @index_list,
        "number_of_indexes sees right no. of indexes in new db" );

    # Check that we get back the indexes that we inserted
    $read_indexes = $map->list_all_indexes;
    is_deeply( [ sort @$read_indexes ], [ sort @index_list ],
               "...and list_all_indexes sees the right ones" );

    # check that we can iterate over the indexes and delete
    # indexes from the whole system and get back *exactly*
    # what we are supposed to
    for my $i ( 0 .. $#index_list ) {
        my $first_index = $map->first_index_in_group( -group => $group );
        is( $first_index, $index_list[$#index_list - $i],
            "first_index_in_group is correct after $i deletions"
            . " from entire system" );

        is( $map->first_index, $index_list[$#index_list - $i],
            "...so is first_index" );

        is( $map->number_of_indexes, scalar(@index_list) - $i,
            "...so is number_of_indexes" );

        my @remaining_indexes = ( $first_index );
        my $index = $first_index;
        my $next_index;
        while ( defined ( $next_index =
                  $map->next_index_in_group( -group => $group,
                                             -index => $index ) )
              ) {
            push @remaining_indexes, $next_index;
            $index = $next_index;
          }

        my @slice = @index_list[0 .. $#index_list - $i];
        # Reverse the slice since the indexes come out in the reverse
        # order to going in (ie, last index added is considered to be
        # the first index)
        @slice = reverse @slice;
        print "# Remaining indexes should be: " . join(" ", @slice) . "\n";
        print "# and in fact are: " . join(" ", @remaining_indexes) . "\n";
         is_deeply( \@remaining_indexes, \@slice,
                   "...next_index_in_group works for remaining indexes" );

        ok( $map->remove_index_from_all( -index => $first_index ),
            "removed index from system" );
    }

    # Clean up to avoid interfering with other tests.
    $map->clear_all;
}


sub load_test_data {
    my ( $map, $group, $test_set, $index_order_ref ) = @_;

    # Want to make sure we add the indexes in a known order, since we'll
    # be processing them one at a time later on.
    foreach my $index ( @$index_order_ref ) {
        my $entry = $test_set->{$index};
        my $data  = $entry->{-data};
        $map->add_index( -index => $index, -data => $data );
        my %keys  = %{ $entry->{-keys} };
        foreach my $key ( keys %keys ) {
            $map->add_entry_to_group ( -group   => $group,
                                       -index   => $index,
                                       -key     => $key,
                                       -ranking => $keys{$key} );
        }
    }
}

