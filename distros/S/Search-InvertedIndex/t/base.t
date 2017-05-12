#!/usr/bin/perl -w

use strict;
use lib ('./blib','./lib','../blib','../lib');
use Search::InvertedIndex;

my @do_tests = (1..11);
#@do_tests=(200);
my $test_map = "test-inv_index.$$";

local $| = 1;

my $db_spec ={
             -map_name => $test_map,
                -multi => 1,
            -file_mode => 0644,
            -lock_mode => 'EX',
         -lock_timeout => 5,
       -blocking_locks => 0,
            -cachesize => 5000000,
        -write_through => 0, 
      -read_write_mode => 'RDWR',
 };

my $test_subs = { 1 => { -code => \&test1, -desc =>  ' open/lock database.....' },
                  2 => { -code => \&test2, -desc =>  ' reopen/lock database...' },
                  3 => { -code => \&test3, -desc =>  ' bare group add/remove..' },
                  4 => { -code => \&test4, -desc =>  ' bare key add/remove....' },
                  5 => { -code => \&test5, -desc =>  ' bare index add/remove..' },
                  6 => { -code => \&test6, -desc =>  ' entry add/remove.......' },
                  7 => { -code => \&test7, -desc =>  ' index data/key removal.' },
                  8 => { -code => \&test8, -desc =>  ' update.................' },
                  9 => { -code => \&test9, -desc =>  ' preload................' },
                 10 => { -code => \&test10, -desc => 'update + search........' },
                 11 => { -code => \&test11, -desc => 'preload + search.......' },
                 200 => { -code => \&test200, -desc => 'preload timing test.' },
                 };

print $do_tests[0],'..',$do_tests[$#do_tests],"\n";
print STDERR "\n";
my $n_failures = 0;
foreach my $test (@do_tests) {
    my $sub  = $test_subs->{$test}->{-code};
    my $desc = $test_subs->{$test}->{-desc};
    my $failure = '';
    eval { $failure = &$sub; };
    if ($@) {
        $failure = $@;
    }
    if ($failure ne '') {
        chomp $failure;
        print "not ok $test\n";
        print STDERR "    $desc - $failure\n";
        $n_failures++;
    } else {
        print "ok $test\n";
        print STDERR "    $desc - ok\n";

    }
	unlink $test_map;
}
print "END\n";
exit;

################################################################################
# Test 'search' with preload_upload                                            #
################################################################################
sub test11 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}

    # Clear the database
    $inv_map->clear_all;

    # Add a test group
    my $group = 'test-group';
    $inv_map->add_group({ -group => $group });

    # Add some data 
    my $keys_per_index = 20;
    my $total_indexes  = 10;
    my $key_range      = 400;
    my $test_set = &make_dataset($keys_per_index,$total_indexes,$key_range);

    my $start_time = time;
    # Make dataset via 'preload_update'
    my @index_list = keys %$test_set;
    my ($key_counter) = {};
    my ($per_index_key_counter) = {};
    my ($per_key_indexes) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
            $per_key_indexes->{$key}->{$index}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->preload_update({ -update => $update });
    }
    $inv_map->update_group({ -group => $group, -block_size => 256 });
    my @key_list = keys (%$key_counter);
#    print STDERR "(load ",int (100 * $total_indexes * $keys_per_index/(time - $start_time))/100," line entries per second) ";

    foreach my $item1 (@key_list[0..1]) {
        # One item search
        my $search = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item1 });
        my $query  = Search::InvertedIndex::Query->new({ -leafs => [$search]});
        my $result = $inv_map->search({ -query => $query });
        if (not defined $result) {
            return "failed - No result object returned from search\n";
        }
        my $number_of_matches = $result->number_of_index_entries;
        if ($number_of_matches != $key_counter->{$item1}) {
			my $result = "failed - Returned $number_of_matches match";
            $result .= "es" if ($number_of_matches != 1);
            $result .= " but expected $key_counter->{$item1} match";
            $result .= "es" if ($key_counter->{$item1} != 1);
            $result .= " for search on key '$item1'\n";
			return $result;
        }
        my $match_index = {};
        for (my $count=0;$count < $number_of_matches; $count++) {
            my ($index,$data,$ranking) = $result->entry({ -number => $count });
            $match_index->{$index}++;
        }
        while (my ($index,$count) = each %$match_index) {
            if (not exists $per_key_indexes->{$item1}->{$index}) {
                return "failure - index '$index' returned for key '$item1' incorrectly\n";
            }
        }

        # Simple two item search, AND condition
        foreach my $item2 (@key_list[0..3]) {
            $search     = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item1 });
            my $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item2 });
            $query      = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'and'});
            $result     = $inv_map->search({ -query => $query });
            my $expected = {};
            my $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result = "es" if ($number_of_matches != 1);
                $result = " but expected $expected match";
                $result = "es" if ($expected_matches != 1);
                $result = " for search on key ($item1 AND $item2)\n";
                return $result; 
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (not (exists ($per_key_indexes->{$item1}->{$index}) and 
                         exists ($per_key_indexes->{$item2}->{$index}))) {
                    return "failure - index '$index' returned for query ($item1 AND $item2) incorrectly\n";
                }
            }
    
            # Simple two item search, OR condition
            $search  = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item1 });
            $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item2 });
            $query   = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'or'});
            $result  = $inv_map->search({ -query => $query });
            $expected = {};
            $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (not exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            while (my ($index,$count) = each %{$per_key_indexes->{$item2}}) {
                $expected->{$index}++;
                $expected_matches++;
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for query on ($item1 OR $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (not (exists ($per_key_indexes->{$item1}->{$index}) or
                         exists ($per_key_indexes->{$item2}->{$index}))) {
                    return "failure - index '$index' returned for query ($item1 OR $item2) incorrectly\n";
                }
            }
    
            # Simple two item search, NAND condition
            $search  = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item1 });
            $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item2 });
            $query  = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'nand'});
            $result = $inv_map->search({ -query => $query });
            $expected = {};
            $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (not exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            while (my ($index,$count) = each %{$per_key_indexes->{$item2}}) {
                if (not exists $per_key_indexes->{$item1}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for query on ($item1 NAND $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (exists ($per_key_indexes->{$item1}->{$index}) and 
                         exists ($per_key_indexes->{$item2}->{$index})) {
                    return "failure - index '$index' returned for query ($item1 NAND $item2) incorrectly\n";
                }
            }
        }
    }
	$inv_map->close;

    '';
}

################################################################################
# Test 'search' + 'upload'                                                     #
################################################################################
sub test10 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}

    # Clear the database
    $inv_map->clear_all;

    # Add a test group
    my $group = 'test-group';
    $inv_map->add_group({ -group => $group });

    # Add some data 
    my $keys_per_index = 20;
    my $total_indexes  = 10;
    my $key_range      = 400;
    my $test_set = &make_dataset($keys_per_index,$total_indexes,$key_range);

    # Make dataset via 'update'
    my $start_time = time;
    my @index_list = keys %$test_set;
    my ($key_counter) = {};
    my ($per_index_key_counter) = {};
    my ($per_key_indexes) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
            $per_key_indexes->{$key}->{$index}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->update({ -update => $update });
    }
    my @key_list = keys (%$key_counter);
#    print STDERR "(load ",int (100 * $total_indexes * $keys_per_index/(time - $start_time))/100," line entries per second) ";
    
    # Test searches
    foreach my $item1 (@key_list[0..1]) {
        # One item search
        my $search = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item1 });
        my $query  = Search::InvertedIndex::Query->new({ -leafs => [$search]});
        my $result = $inv_map->search({ -query => $query });
        if (not defined $result) {
            return "failed - No result object returned from search\n";
        }
        my $number_of_matches = $result->number_of_index_entries;
        if ($number_of_matches != $key_counter->{$item1}) {
            my $result = "failed - Returned $number_of_matches match";
            $result   .= "es" if ($number_of_matches != 1);
            $result   .= " but expected $key_counter->{$item1} match";
            $result   .= "es" if ($key_counter->{$item1} != 1);
            $result   .= " for search on key '$item1'\n";
            return $result;
        }
        my $match_index = {};
        for (my $count=0;$count < $number_of_matches; $count++) {
            my ($index,$data,$ranking) = $result->entry({ -number => $count });
            $match_index->{$index}++;
        }
        while (my ($index,$count) = each %$match_index) {
            if (not exists $per_key_indexes->{$item1}->{$index}) {
                return "failure - index '$index' returned for key '$item1' incorrectly\n";
            }
        }

        # Simple two item search, AND condition
        foreach my $item2 (@key_list[0..3]) {
            $search     = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item1 });
            my $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, '-key' => $item2 });
            $query      = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'and'});
            $result     = $inv_map->search({ -query => $query });
            my $expected = {};
            my $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for search on query ($item1 AND $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (not (exists ($per_key_indexes->{$item1}->{$index}) and 
                         exists ($per_key_indexes->{$item2}->{$index}))) {
                    return "failure - index '$index' returned for query ($item1 AND $item2) incorrectly\n";
                }
            }
    
            # Simple two item search, OR condition
            $search  = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item1 });
            $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item2 });
            $query   = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'or'});
            $result  = $inv_map->search({ -query => $query });
            $expected = {};
            $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (not exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            while (my ($index,$count) = each %{$per_key_indexes->{$item2}}) {
                $expected->{$index}++;
                $expected_matches++;
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for search on query ($item1 OR $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (not (exists ($per_key_indexes->{$item1}->{$index}) or
                         exists ($per_key_indexes->{$item2}->{$index}))) {
                    return "failure - index '$index' returned for query ($item1 OR $item2) incorrectly\n";
                }
            }
    
            # Simple two item search, NAND condition
            $search  = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item1 });
            $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item2 });
            $query  = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'nand'});
            $result = $inv_map->search({ -query => $query });
            $expected = {};
            $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (not exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            while (my ($index,$count) = each %{$per_key_indexes->{$item2}}) {
                if (not exists $per_key_indexes->{$item1}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for search on query ($item1 NAND $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (exists ($per_key_indexes->{$item1}->{$index}) and 
                         exists ($per_key_indexes->{$item2}->{$index})) {
                    return "failure - index '$index' returned for query ($item1 NAND $item2) incorrectly\n";
                }
            }
        }
    }

    # Clear the database
    $inv_map->clear_all;

    # Add test group
    $inv_map->add_group({ -group => $group });

    # Make dataset via 'preload_update'
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->preload_update({ -update => $update });
    }
    $inv_map->update_group({ -group => $group, -block_size => 256 });

    foreach my $item1 (@key_list[0..1]) {
        # One item search
        my $search = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item1 });
        my $query  = Search::InvertedIndex::Query->new({ -leafs => [$search]});
        my $result = $inv_map->search({ -query => $query });
        if (not defined $result) {
            return "failed - No result object returned from search\n";
        }
        my $number_of_matches = $result->number_of_index_entries;
        if ($number_of_matches != $key_counter->{$item1}) {
            my $result = "failed - Returned $number_of_matches match";
            $result .= "es" if ($number_of_matches != 1);
            $result .= " but expected $key_counter->{$item1} match";
            $result .= "es" if ($key_counter->{$item1} != 1);
            $result .= " for search on key '$item1'\n";
            return $result;
        }
        my $match_index = {};
        for (my $count=0;$count < $number_of_matches; $count++) {
            my ($index,$data,$ranking) = $result->entry({ -number => $count });
            $match_index->{$index}++;
        }
        while (my ($index,$count) = each %$match_index) {
            if (not exists $per_key_indexes->{$item1}->{$index}) {
                return "failure - index '$index' returned for key '$item1' incorrectly\n";
            }
        }

        # Simple two item search, AND condition
        foreach my $item2 (@key_list[0..3]) {
            $search     = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item1 });
            my $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item2 });
            $query      = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'and'});
            $result     = $inv_map->search({ -query => $query });
            my $expected = {};
            my $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for search on key ($item1 AND $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (not (exists ($per_key_indexes->{$item1}->{$index}) and 
                         exists ($per_key_indexes->{$item2}->{$index}))) {
                    return "failure - index '$index' returned for query ($item1 AND $item2) incorrectly\n";
                }
            }
    
            # Simple two item search, OR condition
            $search  = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item1 });
            $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item2 });
            $query   = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'or'});
            $result  = $inv_map->search({ -query => $query });
            $expected = {};
            $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (not exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            while (my ($index,$count) = each %{$per_key_indexes->{$item2}}) {
                $expected->{$index}++;
                $expected_matches++;
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for query on ($item1 OR $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (not (exists ($per_key_indexes->{$item1}->{$index}) or
                         exists ($per_key_indexes->{$item2}->{$index}))) {
                    return "failure - index '$index' returned for query ($item1 OR $item2) incorrectly\n";
                }
            }
    
            # Simple two item search, NAND condition
            $search  = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item1 });
            $search2 = Search::InvertedIndex::Query::Leaf->new({ -group => $group, -key => $item2 });
            $query  = Search::InvertedIndex::Query->new({ -leafs => [$search,$search2], -logic => 'nand'});
            $result = $inv_map->search({ -query => $query });
            $expected = {};
            $expected_matches = 0;
            while (my ($index,$count) = each %{$per_key_indexes->{$item1}}) {
                if (not exists $per_key_indexes->{$item2}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            while (my ($index,$count) = each %{$per_key_indexes->{$item2}}) {
                if (not exists $per_key_indexes->{$item1}->{$index}) {
                    $expected->{$index}++;
                    $expected_matches++;
                }
            }
            $number_of_matches = $result->number_of_index_entries;
            if ($number_of_matches != $expected_matches) {
                my $result = "failed - Returned $number_of_matches match";
                $result .= "es" if ($number_of_matches != 1);
                $result .= " but expected $expected match";
                $result .= "es" if ($expected_matches != 1);
                $result .= " for query on ($item1 NAND $item2)\n";
                return $result;
            }
            $match_index = {};
            for (my $count=0;$count < $number_of_matches; $count++) {
                my ($index,$data,$ranking) = $result->entry({ -number => $count });
                $match_index->{$index}++;
            }
            while (my ($index,$count) = each %$match_index) {
                if (exists ($per_key_indexes->{$item1}->{$index}) and 
                         exists ($per_key_indexes->{$item2}->{$index})) {
                    return "failure - index '$index' returned for query ($item1 NAND $item2) incorrectly\n";
                }
            }
        }
    }

	$inv_map->close;
	'';
}

################################################################################
# Test 'preload' timing                                                        #
################################################################################
sub test200 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}

    # Clear the database
    $inv_map->clear_all;

    # Add a test group
    my $group = 'test-group';
    $inv_map->add_group({ -group => $group });

    # Add some data 
    my $test_set = &make_dataset(1000,100);
    my $start_time = time;
    my @index_list = keys %$test_set;
    my ($key_counter) = {};
    my ($per_index_key_counter) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->preload_update({ -update => $update });
    }
    my @key_list = keys (%$key_counter);
    my $load_time = time - $start_time;
    print STDERR "(preload: $load_time seconds, ";
    $start_time = time;
    $inv_map->update_group({ -group => $group, -block_size => 300000 });
    $load_time = time - $start_time;
    print STDERR "group load: $load_time seconds) ";
	$inv_map->close;
    return '';
}

################################################################################
# Test 'preload'                                                               #
################################################################################
sub test9 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}

    # Clear the database
    $inv_map->clear_all;

    # Add a test group
    my $group = 'test-group';
    $inv_map->add_group({ -group => $group });

    # Add some data 
    my $test_set = &make_dataset(100,10);
    my $start_time = time;
    my @index_list = keys %$test_set;
    my ($key_counter) = {};
    my ($per_index_key_counter) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->preload_update({ -update => $update });
    }
    my @key_list = keys (%$key_counter);
    my $load_time = time - $start_time;
    #print STDERR "(preload: $load_time seconds, ";
    $start_time = time;
    $inv_map->update_group({ -group => $group, -block_size => 256 });
    $load_time = time - $start_time;
    #print STDERR "group load: $load_time seconds) ";

    # Check that the index data is readable and correct
    my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
    if ($n_indexes != ($#index_list + 1)) {
        return "failed - a different number of indexes were indicated than written\n";
    }
    # Check the individual entries
    foreach my $index (@index_list) {
        my $data = $inv_map->data_for_index({ '-index' => $index });
        if (not defined $data) {
            return "failed - Could not read data for index '$index'\n";
        }
        my @data_keys = keys %$data;
        foreach my $item (@data_keys) {
            if (not exists $test_set->{$index}->{-data}->{$item}) {
                return "failed - Read data key '$item' that was not written\n";
            }
        }
        @data_keys = keys %{$test_set->{$index}->{-data}};
        foreach my $item (@data_keys) {
            if (not exists $test_set->{$index}->{-data}->{$item}) {
                return "failed - key '$item' was written, but not read\n";
            }
            if ($test_set->{$index}->{-data}->{$item} ne $data->{$item}) {
                return "failed - value '$test_set->{$index}->{-data}->{$item}' was written for key '$item', but '$data->{$item}' was read\n";
            }
        }
    }

    # Check that the key data is readable and correct
    my $n_keys = $inv_map->number_of_keys_in_group({ -group => $group });
    if ($n_keys != ($#key_list + 1)) {
        return "failed - a different number of keys ($n_keys) were indicated than written (",($#key_list+1),")\n";
    }
    # Check the individual keys in the group
    my $read_keys = $inv_map->list_all_keys_in_group({ -group => $group });
    if ($#$read_keys != $#key_list) {
        return "failed - a different number of keys ($#$read_keys + 1) were read than written (",($#key_list+1),")\n";
    }
    my %read_key_counter = ();
    foreach my $key (@$read_keys) {
        if (not exists $key_counter->{$key}) {
            return "failed - a read key '$key' but didn't write it\n";
        }
        if (exists $read_key_counter{$key}) {
            return "failed - the key '$key' was returned more than once from the database for the group\n";
        }
        $read_key_counter{$key} = 1;
    }

    # Verify that key deletion manages indexes and index counters correctly
    # (This checks the integrity of the enum chains)
    # check that we can iterate over the indexes and delete
    # keys from the group and get back *exactly* what we are supposed to
    while ($#key_list > -1) {
        my $delete_key = shift @key_list;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key' from group '$group' (left)\n";
        }
        my @new_index_list = ();
        foreach my $index (@index_list) {
            delete $per_index_key_counter->{$index}->{$delete_key};
            my @per_index_key_list = keys %{$per_index_key_counter->{$index}};
            if ($#per_index_key_list == -1) {
                delete $per_index_key_counter->{$index};
                next;
            }
            push (@new_index_list,$index);
        }
        delete $key_counter->{$delete_key};
        @index_list = @new_index_list;

        my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        my $exp_n_indexes = $#index_list + 1;
        if ($n_indexes != $exp_n_indexes) {
            return "failed - number of indexes in group ($n_indexes) was different than the expected number ($exp_n_indexes) (left)\n";
        }
        last if ($n_indexes == 0);
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
    }    

    # Reload data set
    @index_list = keys %$test_set;
    $key_counter = {};
    $per_index_key_counter = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->preload_update({ -update => $update });
    }
    $inv_map->update_group({ -group => $group, -block_size => 256 });
    @key_list = keys (%$key_counter);

    # Now from the right
    while ($#key_list > -1) {
        my $delete_key = pop @key_list;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key' from group '$group' (right)\n";
        }
        my @new_index_list = ();
        foreach my $index (@index_list) {
            delete $per_index_key_counter->{$index}->{$delete_key};
            my @per_index_key_list = keys %{$per_index_key_counter->{$index}};
            if ($#per_index_key_list == -1) {
                delete $per_index_key_counter->{$index};
                next;
            }
            push (@new_index_list,$index);
        }
        delete $key_counter->{$delete_key};
        @index_list = @new_index_list;

        my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        my $exp_n_indexes = $#index_list + 1;
        if ($n_indexes != $exp_n_indexes) {
            return "failed - number of indexes in group ($n_indexes) was different than the expected number ($exp_n_indexes) (right)\n";
        }
        last if ($n_indexes == 0);
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (right)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (right)\n";
        }
    }

    $inv_map->close;
	
	'';
}

###############################################################################
# Generate a large normal curve random dataset                                #
###############################################################################

sub make_dataset {
    my ($max_keys,$n_indexes,$range) = @_;

    $range = 300 if (not defined $range);
    my $dataset = {};
    for (my $count=0; $count < $n_indexes; $count++) {
        my $index = $count;
        my $data   = { int(rand(987234)) => int(rand (9823123)) };
        $dataset->{$index}->{-data} = $data; 
        for (my $key_counter=0; $key_counter < $max_keys; $key_counter++) {
            my $key     = int (rand ($range/3) +rand($range/3) + rand($range/3));
            my $ranking = int (rand (60000)) - 30000;
            $dataset->{$index}->{'-keys'}->{$key} = $ranking; 
        }
    }
    $dataset;
}

################################################################################
# Test 'update'                                                                #
################################################################################
sub test8 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    # Clear the database
    $inv_map->clear_all;

    # Add a test group
    my $group = 'test-group';
    $inv_map->add_group({ -group => $group });

    # Add some data 
    my $test_set = &make_dataset(10,5);

    my @index_list = keys %$test_set;
    my ($key_counter) = {};
    my ($per_index_key_counter) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->update({ -update => $update });
    }
    my @key_list = keys (%$key_counter);

    # Check that the index data is readable and correct
    foreach my $index (@index_list) {
        my $data = $inv_map->data_for_index({ '-index' => $index });
        if (not defined $data) {
            return "failed - Could not read data for index '$index'\n";
        }
        my @data_keys = keys %$data;
        foreach my $item (@data_keys) {
            if (not exists $test_set->{$index}->{-data}->{$item}) {
                return "failed - Read data key '$item' that was not written\n";
            }
        }
        @data_keys = keys %{$test_set->{$index}->{-data}};
        foreach my $item (@data_keys) {
            if (not exists $test_set->{$index}->{-data}->{$item}) {
                return "failed - key '$item' was written, but not read\n";
            }
            if ($test_set->{$index}->{-data}->{$item} ne $data->{$item}) {
                return "failed - value '$test_set->{$index}->{-data}->{$item}' was written for key '$item', but '$data->{$item}' was read\n";
            }
        }
    }

    # Check that deletion of non-existing indexes from system does not result in
    # problems.
    my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
    $inv_map->remove_index_from_all({ -index => 'no such animal' });
    my $new_n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
    if ($new_n_indexes != $n_indexes) {
        return ("failed - Deletion of non-existent keys resulted in incorrect index counts.\n");
    }

    # Verify that key deletion manages indexes and index counters correctly

    # check that we can iterate over the indexes and delete
    # keys from the group and get back *exactly* what we are supposed to
    while ($#key_list > -1) {
        my $delete_key = shift @key_list;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key' from group '$group' (left)\n";
        }
        my @new_index_list = ();
        foreach my $index (@index_list) {
            delete $per_index_key_counter->{$index}->{$delete_key};
            my @per_index_key_list = keys %{$per_index_key_counter->{$index}};
            if ($#per_index_key_list == -1) {
                delete $per_index_key_counter->{$index};
                next;
            }
            push (@new_index_list,$index);
        }
        delete $key_counter->{$delete_key};
        @index_list = @new_index_list;

        my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        my $exp_n_indexes = $#index_list + 1;
        if ($n_indexes != $exp_n_indexes) {
            return "failed - number of indexes in group ($n_indexes) was different than the expected number ($exp_n_indexes)\n";
        }
        last if ($n_indexes == 0);
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
    }    

    # Reload data set
    @index_list = keys %$test_set;
    $key_counter = {};
    $per_index_key_counter = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->update({ -update => $update });
    }
    @key_list = keys (%$key_counter);

    # Now from the right
    while ($#key_list > -1) {
        my $delete_key = pop @key_list;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key' from group '$group' (right)\n";
        }
        my @new_index_list = ();
        foreach my $index (@index_list) {
            delete $per_index_key_counter->{$index}->{$delete_key};
            my @per_index_key_list = keys %{$per_index_key_counter->{$index}};
            if ($#per_index_key_list == -1) {
                delete $per_index_key_counter->{$index};
                next;
            }
            push (@new_index_list,$index);
        }
        delete $key_counter->{$delete_key};
        @index_list = @new_index_list;

        my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        my $exp_n_indexes = $#index_list + 1;
        if ($n_indexes != $exp_n_indexes) {
            return "failed - number of indexes in group ($n_indexes) was different than the expected number ($exp_n_indexes)\n";
        }
        last if ($n_indexes == 0);
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
    }

    # Reload data set
    @index_list = keys %$test_set;
    $key_counter = {};
    $per_index_key_counter = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        my $update = Search::InvertedIndex::Update->new({ 
                 -group => $group,   '-index' => $index, 
                  -data => $data,     '-keys' => $keys });
        $inv_map->update({ -update => $update });
    }
    @key_list = keys (%$key_counter);


    # Progessively clear the dataset using update
    foreach my $index (@index_list) {
        my $update = Search::InvertedIndex::Update->new({
            -group => $group, '-index' => $index });
        $inv_map->update({ -update => $update });
    }
   
	$inv_map->close;
	'';
}

################################################################################
# Test that index data is being written and read correctly                     #
# Also test that key deletion works correctly via the 'remove_key_from_group'  #
# method                                                                       #
################################################################################
sub test7 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    # Clear the database
    $inv_map->clear_all;

    # Add a test group
    my $group = 'test-group';
    $inv_map->add_group({ -group => $group });

    # Add some data 
    my $test_set = &make_dataset(10,5);

    my @index_list = keys %$test_set;
    my ($key_counter) = {};
    my ($per_index_key_counter) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              -key => $key, -ranking => $keys->{$key}, });
        }
    }
    my @key_list = keys (%$key_counter);

    # Check that the index data is readable and correct
    foreach my $index (@index_list) {
        my $data = $inv_map->data_for_index({ '-index' => $index });
        if (not defined $data) {
            return "failed - Could not read data for index '$index'\n";
        }
        my @data_keys = keys %$data;
        foreach my $item (@data_keys) {
            if (not exists $test_set->{$index}->{-data}->{$item}) {
                return "failed - Read data key '$item' that was not written\n";
            }
        }
        @data_keys = keys %{$test_set->{$index}->{-data}};
        foreach my $item (@data_keys) {
            if (not exists $test_set->{$index}->{-data}->{$item}) {
                return "failed - key '$item' was written, but not read\n";
            }
            if ($test_set->{$index}->{-data}->{$item} ne $data->{$item}) {
                return "failed - value '$test_set->{$index}->{-data}->{$item}' was written for key '$item', but '$data->{$item}' was read\n";
            }
        }
    }

    # Verify that key deletion manages indexes and index counters correctly

    # check that we can iterate over the indexes and delete
    # keys from the group and get back *exactly* what we are supposed to
    while ($#key_list > -1) {
        my $delete_key = shift @key_list;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key' from group '$group' (left)\n";
        }
        my @new_index_list = ();
        foreach my $index (@index_list) {
            delete $per_index_key_counter->{$index}->{$delete_key};
            my @per_index_key_list = keys %{$per_index_key_counter->{$index}};
            if ($#per_index_key_list == -1) {
                delete $per_index_key_counter->{$index};
                next;
            }
            push (@new_index_list,$index);
        }
        delete $key_counter->{$delete_key};
        @index_list = @new_index_list;

        my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        my $exp_n_indexes = $#index_list + 1;
        if ($n_indexes != $exp_n_indexes) {
            return "failed - number of indexes in group ($n_indexes) was different than the expected number ($exp_n_indexes)\n";
        }
        last if ($n_indexes == 0);
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
    }    

    # reload data set
    @index_list = keys %$test_set;
    ($key_counter) = {};
    ($per_index_key_counter) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              -key => $key, -ranking => $keys->{$key}, });
        }
    }
    @key_list = keys (%$key_counter);
    
    # Now from the right
    while ($#key_list > -1) {
        my $delete_key = pop @key_list;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key' from group '$group' (right)\n";
        }
        my @new_index_list = ();
        foreach my $index (@index_list) {
            delete $per_index_key_counter->{$index}->{$delete_key};
            my @per_index_key_list = keys %{$per_index_key_counter->{$index}};
            if ($#per_index_key_list == -1) {
                delete $per_index_key_counter->{$index};
                next;
            }
            push (@new_index_list,$index);
        }
        delete $key_counter->{$delete_key};
        @index_list = @new_index_list;

        my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        my $exp_n_indexes = $#index_list + 1;
        if ($n_indexes != $exp_n_indexes) {
            return "failed - number of indexes in group ($n_indexes) was different than the expected number ($exp_n_indexes)\n";
        }
        last if ($n_indexes == 0);
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
    }

	$inv_map->close;
	'';
}

####################################################
# Test entry addition and deletions index behavior #
####################################################
sub test6 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    # Clear the database
    $inv_map->clear_all;

    # Add a test group
    my $group = 'test-group';
    $inv_map->add_group({ -group => $group });

    # Add some indexes 
    my $test_set = &make_dataset(4,4);

    my @index_list = keys %$test_set;
    my @key_list = ();
    my ($key_counter) = {};
    my ($per_index_key_counter) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              '-key' => $key, -ranking => $keys->{$key}, });
        }
    }
    @key_list = keys (%$key_counter);

    # Check that there are the correct number of keys in the group.
    my $number_of_keys_in_group = $inv_map->number_of_keys_in_group({ -group => $group });
    if ((not defined $number_of_keys_in_group) or ($number_of_keys_in_group != ($#key_list+1))) {
        return "failed - Number of keys in new database was '$number_of_keys_in_group' rather than '",$#key_list+1,"'\n";
    }

    # Check that we get back the keys that we inserted
    my $read_keys = $inv_map->list_all_keys_in_group({ -group => $group });
    if ($#$read_keys != $#key_list) {
        return ("failed - The list of keys added (","@key_list",") was not the same as the keys read (", "@$read_keys",")\n");
    }
    my %test_key_names = map { $_ => 0 } @key_list;
    my @errors = (); 
    foreach my $key (@$read_keys) {
        if (not exists $test_key_names{$key}) {
            push (@errors,$key);
        }
    }
    if ($#errors > -1) {
        return "failed - indexes (","@errors",") were read that were not written\n";
    }

    # Check that there are the correct number of indexes in the group.
    my $number_of_indexes_in_group = $inv_map->number_of_indexes_in_group({ -group => $group });
    if ((not defined $number_of_indexes_in_group) or ($number_of_indexes_in_group != ($#index_list+1))) {
        return "failed - Number of indexes in new database was '$number_of_indexes_in_group' rather than '",$#index_list+1,"'\n";
    }

    # Check that we get back the indexes that we inserted from the group
    my $read_indexes = $inv_map->list_all_indexes_in_group({ -group => $group });
    if ($#$read_indexes != $#index_list) {
        return ("failed - The list of indexes added (","@index_list",") was not the same as the indexes read (", "@$read_indexes",")\n");
    }
    my %test_index_names = map { $_ => 0 } @index_list;
    @errors = (); 
    foreach my $index (@$read_indexes) {
        if (not exists $test_index_names{$index}) {
            push (@errors,$index);
        }
    }
    if ($#errors > -1) {
        return "failed - indexes (","@errors",") were read that were not written\n";
    }

    # check that we can iterate over the indexes and delete
    # indexes from the group and get back *exactly* what we are supposed to
    while ($#index_list > -1) {
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
        my $delete_index = shift @index_list;
        if (not $inv_map->remove_index_from_group({ -group => $group, '-index' => $delete_index})) {
            return "failed - remove_index_from_group failed to remove index '$delete_index' from group '$group' (left)\n";
        }
    }    

    # Reload the test data
    @index_list = keys %$test_set;
    @key_list = ();
    ($key_counter) = {};
    ($per_index_key_counter) = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
            $per_index_key_counter->{$index}->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              -key => $key, -ranking => $keys->{$key}, });
        }
    }
    @key_list = keys (%$key_counter);

    while ($#index_list > -1) {
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (right)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (right)\n";
        }
        my $delete_index = pop @index_list;
        if (not $inv_map->remove_index_from_group({ -group => $group, '-index' => $delete_index})) {
            return "failed - remove_index_from_group failed to remove index '$delete_index' from group '$group' (right)\n";
        }
    }

    # check that we can iterate over the indexes and delete
    # indexes from the whole system and get back *exactly*
    # what we are supposed to
    @index_list = keys %$test_set;
    @key_list = ();
    $key_counter = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              '-key' => $key, -ranking => $keys->{$key}, });
        }
    }
    @key_list = keys %$key_counter;

    # Check that there are the correct number of indexes in the system.
    my $number_of_indexes = $inv_map->number_of_indexes;
    if ((not defined $number_of_indexes) or ($number_of_indexes != ($#index_list+1))) {
        return "failed - Number of indexes in new database was '$number_of_indexes' rather than '",$#index_list+1,"'\n";
    }

    # Check that we get back the indexes that we inserted from the system 
    $read_indexes = $inv_map->list_all_indexes;
    if ($#$read_indexes != $#index_list) {
        return ("failed - The list of indexes added (","@index_list",") was not the same as the indexes read (", "@$read_indexes",")\n");
    }
    %test_index_names = map { $_ => 0 } @index_list;
    @errors = (); 
    foreach my $index (@$read_indexes) {
        if (not exists $test_index_names{$index}) {
            push (@errors,$index);
        }
    }
    if ($#errors > -1) {
        return "failed - indexes (","@errors",") were read that were not written\n";
    }

    while ($#index_list > -1) {
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
        my $delete_index = shift @index_list;
        if (not $inv_map->remove_index_from_all({ '-index' => $delete_index})) {
            return "failed - remove_index_from_all failed to remove index '$delete_index'(left)\n";
        }
    }    

    # Now again, this time from the right.
    @index_list = keys %$test_set;
    @key_list = ();
    $key_counter = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              -key => $key, -ranking => $keys->{$key}, });
        }
    }
    @key_list = keys %$key_counter;

    while ($#index_list > -1) {
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index_in_group({ -group => $group });
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (right)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index_in_group({ -group => $group, '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (right)\n";
        }
        my $delete_index = pop @index_list;
        if (not $inv_map->remove_index_from_all({ '-index' => $delete_index})) {
            return "failed - remove_index_from_all failed to remove index '$delete_index' (right)\n";
        }
    }

    # check that we can iterate over the indexes and delete
    # indexes from the whole system and get back the *global*
    # indexes properly
    @index_list = keys %$test_set;
    @key_list = ();
    $key_counter = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              -key => $key, -ranking => $keys->{$key}, });
        }
    }
    @key_list = keys %$key_counter;

    while ($#index_list > -1) {
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index;
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index({ '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
        my $delete_index = shift @index_list;
        if (not $inv_map->remove_index_from_all({ '-index' => $delete_index})) {
            return "failed - remove_index_from_all failed to remove index '$delete_index'(left)\n";
        }
        if ($inv_map->number_of_indexes != ($#index_list+1)) {
            return "failed - remove_index_from_all left incorrect number_of_indexes\n";
        }
    }    

    # Now again, this time from the right.
    @index_list = keys %$test_set;
    @key_list = ();
    $key_counter = {};
    foreach my $index (@index_list) {
        my $entry = $test_set->{$index};
        my $data = $entry->{-data};
        my $keys = $entry->{'-keys'};
        my @test_keys = keys %$keys;
        foreach my $key (@test_keys) {
            $key_counter->{$key}++;
        }
        $inv_map->add_index({ '-index' => $index, -data => $data });
        foreach my $key (@test_keys) {
            $inv_map->add_entry_to_group ({ -group => $group, '-index' => $index, 
                                              '-key' => $key, -ranking => $keys->{$key}, });
        }
    }
    @key_list = keys %$key_counter;

    while ($#index_list > -1) {
        my %test_index_names = map { $_ => 0 } @index_list;
        my $first_index = $inv_map->first_index;
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $index_list[$#index_list]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$index_list[$#index_list]' (right)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index({'-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (right)\n";
        }
        my $delete_index = pop @index_list;
        if (not $inv_map->remove_index_from_all({ '-index' => $delete_index})) {
            return "failed - remove_index_from_all failed to remove index '$delete_index' (right)\n";
        }
        if ($inv_map->number_of_indexes != ($#index_list+1)) {
            return "failed - remove_index_from_all left incorrect number_of_indexes\n";
        }
    }
	$inv_map->close;
	'';
}

# Test index addition and deletions
sub test5 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    # Clear the database
    $inv_map->clear_all;

    # Check that there are 0 indexes in the system.
    my $number_of_indexes = $inv_map->number_of_indexes;
    if ((not defined $number_of_indexes) or ($number_of_indexes != 0)) {
        return "failed - Number of indexes in new database was '$number_of_indexes' rather than '0'\n";
    }

    # Explicitly add a list of indexes
    my (@test_indexes) = ('blah','hello','whaah!');    
    foreach my $index (@test_indexes) {
        $inv_map->add_index({ '-index' => $index, -data => {}, });
    }

    # Check that there are the correct number of indexes in the system.
    $number_of_indexes = $inv_map->number_of_indexes;
    if ((not defined $number_of_indexes) or ($number_of_indexes != ($#test_indexes+1))) {
        return "failed - Number of indexes in new database was '$number_of_indexes' rather than '",$#test_indexes+1,"'\n";
    }

    # Check that we get back what we inserted
    my $indexes = $inv_map->list_all_indexes;
    if ($#$indexes != $#test_indexes) {
        return ("failed - The list of indexes added (","@test_indexes",") was not the same as the indexes read (", "@$indexes",")\n");
    }
    my %test_index_names = map { $_ => 0 } @test_indexes;
    my @errors = (); 
    foreach my $index (@$indexes) {
        if (not exists $test_index_names{$index}) {
            push (@errors,$index);
        }
    }
    if ($#errors > -1) {
        return "failed - indexes (","@errors",") were read that were not written\n";
    }

    # check that we can iterate over the indexes and delete
    # indexes from the left and get back *exactly* what we are supposed to
    while ($#test_indexes > -1) {
        my %test_index_names = map { $_ => 0 } @test_indexes;
        my $first_index = $inv_map->first_index;
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $test_indexes[$#test_indexes]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$test_indexes[$#test_indexes]' (left)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index({ '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (left)\n";
        }
        my $delete_index = pop @test_indexes;
        if (not $inv_map->remove_index_from_all({ '-index' => $delete_index})) {
            return "failed - remove_index_from_all failed to remove index '$delete_index' (left)\n";
        }
    }    

    # Now do it from the right side
    @test_indexes = ('blah','hello','whaah!');    
    foreach my $index (@test_indexes) {
        $inv_map->add_index({ '-index' => $index, -data => {} });
    }
    while ($#test_indexes > -1) {
        my %test_index_names = map { $_ => 0 } @test_indexes;
        my $first_index = $inv_map->first_index;
        my $indexes = [$first_index];
        my $index = $first_index;
        if ($index ne $test_indexes[$#test_indexes]) {
            return "failed - index '$index' was returned by 'first_index', but it should have been '$test_indexes[$#test_indexes]' (right)\n";
        }
        my @errors = ();
        $test_index_names{$index}++;    
        while (my $next_index = $inv_map->next_index({ '-index' => $index })) {
            $index = $next_index;
            $test_index_names{$index}++;    
            if ($test_index_names{$index} > 1) {
                push (@errors,$index);
            }
        }
        if ($#errors > -1) {
            return "failed - Indexes (","@errors",") were read more than once (right)\n";
        }
        my $delete_index = shift @test_indexes;
        if (not $inv_map->remove_index_from_all({ '-index' => $delete_index})) {
            return "failed - remove_index_from_all failed to remove index '$delete_index'\n";
        }
        
    }    

    $inv_map->close;
	'';
}

# Test bare key addition and deletion
sub test4 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    # Clear the database
    $inv_map->clear_all;

    # Check that there are 0 keys in the system.
    my $number_of_keys = $inv_map->number_of_keys;
    if ((not defined $number_of_keys) or ($number_of_keys != 0)) {
        return "failed - Number of keys in new database was '$number_of_keys' rather than '0'\n";
    }

    # Create a test group
    my $group = 'test';    
    $inv_map->add_group({ -group => $group });

    # Check that there are 0 keys in the group.
    my $number_of_keys_in_group = $inv_map->number_of_keys_in_group({ -group => $group });
    if ((not defined $number_of_keys_in_group) or ($number_of_keys_in_group != 0)) {
        return "failed - Number of keys in new database was '$number_of_keys_in_group' rather than '0'\n";
    }

    # Explicitly add a list of keys
    my (@test_keys) = ('blah','hello','whaah!');    
    foreach my $key (@test_keys) {
        $inv_map->add_key_to_group({ -group => $group, -key => $key });
    }

    # Check that there are the correct number of keys in the group.
    $number_of_keys_in_group = $inv_map->number_of_keys_in_group({ -group => $group });
    if ((not defined $number_of_keys_in_group) or ($number_of_keys_in_group != ($#test_keys+1))) {
        return "failed - Number of keys in new database was '$number_of_keys_in_group' rather than '",$#test_keys+1,"'\n";
    }

    # Check that we get back what we inserted
    my $keys = $inv_map->list_all_keys_in_group({ -group => $group });
    if ($#$keys != $#test_keys) {
        return ("failed - The list of keys added (","@test_keys",") was not the same as the keys read (", "@$keys",")\n");
    }
    my %test_key_names = map { $_ => 0 } @test_keys;
    my @errors = (); 
    foreach my $key (@$keys) {
        if (not exists $test_key_names{$key}) {
            push (@errors,$key);
        }
    }
    if ($#errors > -1) {
        return "failed - keys (","@errors",") were read that were not written\n";
    }

    # check that we can iterate over the keys and delete
    # keys from the left and get back *exactly* what we are supposed to
    while ($#test_keys > -1) {
        my %test_key_names = map { $_ => 0 } @test_keys;
        my $first_key = $inv_map->first_key_in_group({ -group => $group });
        my $keys = [$first_key];
        my $key = $first_key;
        if ($key ne $test_keys[$#test_keys]) {
            return "failed - Group $group key '$key' was returned by 'first_key_in_group', but it should have been '$test_keys[$#test_keys]' (left)\n";
        }
        my @errors = ();
        $test_key_names{$key}++;    
        while (my $next_key = $inv_map->next_key_in_group({ -group => $group, -key => $key })) {
            $key = $next_key;
            $test_key_names{$key}++;    
            if ($test_key_names{$key} > 1) {
                push (@errors,$key);
            }
        }
        if ($#errors > -1) {
            return "failed - Keys (","@errors",") were read more than once (left)\n";
        }
        my $delete_key = pop @test_keys;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key' (left)\n";
        }
    }    

    # Now do it from the right side
    @test_keys = ('blah','hello','whaah!');    
    foreach my $key (@test_keys) {
        $inv_map->add_key_to_group({ -group => $group, -key => $key });
    }
    while ($#test_keys > -1) {
        my %test_key_names = map { $_ => 0 } @test_keys;
        my $first_key = $inv_map->first_key_in_group({ -group => $group });
        my $keys = [$first_key];
        my $key = $first_key;
        if ($key ne $test_keys[$#test_keys]) {
            return "failed - Group $group key '$key' was returned by 'first_key_in_group', but it should have been '$test_keys[$#test_keys]' (right)\n";
        }
        my @errors = ();
        $test_key_names{$key}++;    
        while (my $next_key = $inv_map->next_key_in_group({ -group => $group, -key => $key })) {
            $key = $next_key;
            $test_key_names{$key}++;    
            if ($test_key_names{$key} > 1) {
                push (@errors,$key);
            }
        }
        if ($#errors > -1) {
            return "failed - Keys (","@errors",") were read more than once (right)\n";
        }
        my $delete_key = shift @test_keys;
        if (not $inv_map->remove_key_from_group({ -group => $group, -key => $delete_key})) {
            return "failed - remove_key_from_group failed to remove key '$delete_key'\n";
        }
        
    }    

    $inv_map->close;
	'';
}

# Test empty groups standalone
sub test3 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    # Clear the database
    $inv_map->clear_all;

    # Try to read groups
    my $groups = $inv_map->list_all_groups;
    if ($#$groups != -1) {
        return "failed - Read groups after clearing database\n";
    }
    my $number_of_groups = $inv_map->number_of_groups; 
    if ((not defined $number_of_groups) or ('0' ne $inv_map->number_of_groups)) {
        return "failed - 'number_of_groups' ($number_of_groups) should have been '0' and was not\n";
    }
    my @test_groups = ('able','baker','charlie','delta');

    # Explictly add some groups
    foreach my $group (@test_groups) {
        $inv_map->add_group({ -group => $group });
    }

    # Check that there are groups now
    $groups = $inv_map->list_all_groups;
    if ($#$groups == -1) {
        return "failed - Groups could not be added\n";
    }

    # Clear the database again
    $inv_map->clear_all;
    $groups = $inv_map->list_all_groups;
    if ($#$groups != -1) {
        return "failed - Groups (","@$groups",") found after 'clear_all'\n";
    }

    # Set groups and check that we can get them back 
    foreach my $group (@test_groups) {
        $inv_map->add_group({ -group => $group });
    }
    $groups = $inv_map->list_all_groups;
    if ($#$groups != $#test_groups) {
        return ("failed - The list of groups added (","@test_groups",") was not the same as the groups read (", "@$groups",")\n");
    }
    my %test_group_names = map { $_ => 0 } @test_groups;
    my @errors = (); 
    foreach my $group (@$groups) {
        if (not exists $test_group_names{$group}) {
            push (@errors,$group);
        }
    }
    if ($#errors > -1) {
        return "failed - Groups (","@errors",") were read that were not written\n";
    }

    # Check that deletion of non-existing indexes from system does not result in
    # problems.
    foreach my $group (@test_groups) {
        my $n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        $inv_map->remove_index_from_all({ -index => 'no such animal' });
        my $new_n_indexes = $inv_map->number_of_indexes_in_group({ -group => $group });
        if ($new_n_indexes != $n_indexes) {
            return ("failed - Deletion of non-existent keys resulted in incorrect index counts.\n");
        }
    }

    # check that we can iterate over the groups and delete
    # groups from the left and get back *exactly* what we are supposed to
    while ($#test_groups > -1) {
        my %test_group_names = map { $_ => 0 } @test_groups;
        my $first_group = $inv_map->first_group;
        my $groups = [$first_group];
        my $group = $first_group;
        if ($group ne $test_groups[$#test_groups]) {
            return "failed - Group '$group' was returned by 'first_group', but it should have been '$test_groups[$#test_groups]'\n";
        }
        my @errors = ();
        $test_group_names{$group}++;    
        while (my $next_group = $inv_map->next_group({ -group => $group })) {
            $group = $next_group;
            $test_group_names{$group}++;    
            if ($test_group_names{$group} > 1) {
                push (@errors,$group);
            }
        }
        if ($#errors > -1) {
            return "failed - Groups (","@errors",") were read more than once\n";
        }
        my $delete_group = pop @test_groups;
        $inv_map->remove_group({-group => $delete_group});
    }    

    # Now do it from the right side
    @test_groups = ('able','baker','charlie','delta');

    # Add the test groups
    foreach my $group (@test_groups) {
        $inv_map->add_group({ -group => $group });
    }

    # do the deletions
    while ($#test_groups > -1) {
        my %test_group_names = map { $_ => 0 } @test_groups;
        my $first_group = $inv_map->first_group;
        my $groups = [$first_group];
        my $group = $first_group;
        if ($group ne $test_groups[$#test_groups]) {
            return "failed - Group '$group' was returned by 'first_group', but it should have been '$test_groups[$#test_groups]'\n";
        }
        my @errors = ();
        $test_group_names{$group}++;    
        while (my $next_group = $inv_map->next_group({ -group => $group })) {
            $group = $next_group;
            $test_group_names{$group}++;    
            if ($test_group_names{$group} > 1) {
                push (@errors,$group);
            }
        }
        if ($#errors > -1) {
            return "failed - Groups (","@errors",") were read more than once\n";
        }
        my $delete_group = shift @test_groups;
        $inv_map->remove_group({-group => $delete_group});
        my $number_of_groups = $inv_map->number_of_groups; 
        if (($#test_groups+1) != $inv_map->number_of_groups) {
            return "failed - 'number_of_groups' ($number_of_groups) did not match actual number (",$#test_groups+1,")\n";
		}
    }    

    $inv_map->close;
	'';
}

# Test _re_Open database and Set locks.
sub test2 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    my ($status) = $inv_map->status('-open');
    if (not $status) {
        return "failed - database did not successfully open\n";
    }
    my ($lock_mode) = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'EX') {
        return "failed - database did not open locked exclusively.\n";
    }
    $inv_map->lock({-lock_mode => 'SH'});
    $lock_mode = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'SH') {
        return "failed - database did not change to shared locked.\n";
    }
    $inv_map->lock({-lock_mode => 'UN'});
    $lock_mode = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'UN') {
        return "failed - database did not change to unlocked.\n";
    }
    $inv_map->lock({-lock_mode => 'EX'});
    $lock_mode = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'EX') {
        return "failed - database did not change back to exclusively locked.\n";
    }

    $inv_map->close;
	'';
}

# Test Open database and Set locks.
sub test1 {

	# Get the database object
	my $database = Search::InvertedIndex::DB::DB_File_SplitHash->new($db_spec);
	if (not defined $database) {
	    return "failed - Search::InvertedIndex::DB::MultiDB_File could not be initialized\n";
	}

	# Open the database
	my $inv_map  = Search::InvertedIndex->new({ -database => $database });
	if (not defined $inv_map) {
	    return "failed - Search::InvertedIndex could not be initialized\n";
	}
    my ($status) = $inv_map->status('-open');
    if (not $status) {
        return "failed - database did not successfully open\n";
    }
    my ($lock_mode) = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'EX') {
        return "failed - database did not open locked exclusively.\n";
    }
	##SH
    eval { $inv_map->lock({-lock_mode => 'SH'}); };
	if ($@) {
		return "failed - $@";
	}
    $lock_mode = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'SH') {
        return "failed - database did not change to shared locked.\n";
    }

	##UN
    eval { $inv_map->lock({-lock_mode => 'UN'}); };
	if ($@) {
		return "failed - $@";
	}
    $lock_mode = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'UN') {
        return "failed - database did not change to unlocked.\n";
    }

	##EX
    eval { $inv_map->lock({-lock_mode => 'EX'}); };
	if ($@) {
		return "failed - $@";
	}
    $lock_mode = $inv_map->status('-lock_mode');
    if ($lock_mode ne 'EX') {
        return "failed - database did not change back to exclusively locked.\n";
    }

    $inv_map->close;
	'';
}
