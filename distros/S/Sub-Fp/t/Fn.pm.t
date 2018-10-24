package Fn::Test;
use warnings;
use strict;
use parent qw(Test::Class);
use Data::Dumper qw(Dumper);
use Test::More;
use Fn qw(
    map         inc     freduce     flatten
    drop_right  drop    take_right  take
    assoc       fmap    inc         dec      chain
    first       latest  subarray    partial
    __          find    filter      some
    none        uniq    bool        spread   every
    len
);

sub len__returns_0_when_args_undef{
    is(len(), 0);
}

sub len__returns_0_when_empty_array {
    is(len([]), 0);
}

sub len__returns_0_when_empty_hash {
    is(len({}), 0);
}

sub len__returns_0_when_empty_string {
    is(len(''), 0);
}

sub len__returns_length_of_array {
    is(len([1,2,3,4,5]), 5);
}

sub len__returns_length_of_hash {
    is(
        len({ key1 => 'val', key2 => 'val', key3 => 'val' }),
        3
    );
}

sub len__returns_length_of_string {
    is(len('abcd'), 4);
}


sub freduce__returns_undef_when_no_args :Tests {
    is(freduce(), undef);
}

sub freduce__returns_undef_when_incomplete_args :Tests {
    is(freduce([]), undef);
}

sub freduce__returns_new_val_from_collection :Tests {
       my $result = freduce(sub {
        my ($accum, $val) = @_;
        return $accum + $val
    }, [1,2,3,4]);

    is($result, 10);
}

sub freduce__returns_new_val_from_collection_using_accum :Tests {
    my $result = freduce(sub {
        my ($accum, $val) = @_;
        return $accum + $val
    }, 100, [1,2,3,4]);

    is($result, 110);
}

sub freduce__returns_new_val_from_collection_using_accum_with_new_type :Tests {
    my $result = freduce(sub {
        my ($accum, $val) = @_;
        return {
            spread($accum),
            $val => "The val became a key!"
        }
    }, {}, ["first", "second", "third"]);

    my $expected = {
        first  => "The val became a key!",
        second => "The val became a key!",
        third  => "The val became a key!",
    };

    is_deeply($result, $expected);
}

sub every__returns_1_when_undef :Tests {
    is(every(), 1)
}

sub every__returns_1_when_empty :Tests {
    is(every(sub {}, []), 1)
}

sub every__returns_1_when_predicate_matches_everything :Tests {
    is(
        every(sub { $_[0] eq 'test'}, ['test','test','test','test']),
        1,
    )
}

sub every__returns_0_when_predicate_only_matches_some :Tests {
    is(
        every(sub { $_[0] eq 'test'}, ['test','test','test','nontest']),
        0,
    )
}

sub bool__returns_0_when_undef :Tests {
    is(bool(), 0)
}

sub bool__returns_0_when_falsy :Tests {
    is(bool(''), 0)
}

sub bool__returns_1_when_truthy :Tests {
    is(bool([]), 1);
}

sub bool__returns_1_when_string_truthy :Tests {
    is(bool("string"), 1);
}

sub uniq__returns_empty_array_when_array_empty :Tests {
    is_deeply(uniq([]), []);
}

sub uniq__returns_empty_array_when_args_undef :Tests {
    is_deeply(uniq(), []);
}

sub uniq__returns_unique_array_when_duplicates :Tests {
    is_deeply(uniq([1,1,2,2,3,4,5]), [1,2,3,4,5]);
}

sub uniq__returns_unique_array_in_same_order_when_duplicates :Tests {
    is_deeply(
        uniq(["cheese", "is", "very", "very", "tasty"]),
        ["cheese", "is", "very", "tasty"]
    );
}

sub uniq__returns_new_array :Tests {
    ok( uniq([1,1,2,2,3,3]) != [1,2,3] );
}


sub some__returns_false_when_empty_args :Tests {
    is(some(sub {}, []), 0)
}

sub some__returns_false_when_args_undef :Tests {
    is(some(), 0)
}

sub some__returns_true_if_one_matches_predicate :Tests {
    is(
        some(sub { $_[0] > 2}, [1,1,1,1,3]),
        1
    );
}

sub some__returns_false_if_none_match_predicate :Tests {
    is(
        some(sub { $_[0] > 10}, [1,1,1,1,3]),
        0
    );
}

sub none__returns_true_when_empty_args :Tests {
    is(none(sub{}, []), 1);
}

sub none__returns_true_when_args_undef :Tests {
    is(none(), 1);
}

sub none__returns_true_when_none_match_predicate :Tests {
    is(
        none(sub { $_[0] > 3 }, [1,2,3,3,3,3,3]),
        1
    )
}

sub none__returns_false_when_one_matches_predicate :Tests {
    is(
        none(sub { $_[0] > 3 }, [1,2,3,3,3,3,5]),
        0
    )
}

sub none__returns_false_when_multi_matches_predicate :Tests {
    is(
        none(sub { $_[0] > 3 }, [1,2,3,3,3,5,10]),
        0
    )
}

sub spread__returns_empty_list_when_args_undef :Tests {
    is_deeply(
        [ spread() ],
        []
    );
}

sub spread__returns_empty_key_val_when_args_undef :Tests {
    is_deeply(
        { spread() },
        {}
    );
}

sub spread__returns_empty_key_val_when_args_empty :Tests {
    is_deeply(
        { spread({}) },
        {}
    );
}

sub spread__returns_list_when_args_empty :Tests {
    is_deeply(
        [ spread([]) ],
        []
    );
}

sub spread__returns_destructured_list :Tests {
    is_deeply(
        [1, 2, spread([3, 4])],
        [1, 2, 3, 4],
    );
}

sub spread__returns_destructured_key_vals :Tests {
    my $keyval = { key3 => 'val3' };
    is_deeply(
        {
            key => 'val',
            key2 => 'val2',
            spread($keyval)
        },
        {
            key => 'val',
            key2 => 'val2',
            key3 => 'val3',
        }
    );
}

sub find__returns_undef_when_empty_args :Tests {
    is_deeply(find([]), undef);
}

sub find__returns_undef_when_not_found_in_array :Tests {
    is_deeply(
        find(sub { $_[0] > 100}, [1,2,3,4,5]),
        undef,
    );
}

sub find__returns_item_when_found_in_array :Tests {
    is_deeply(
        find(sub { $_[0] > 4}, [1,2,3,4,5]),
        5,
    );
}


#TODO More unit tests
sub filter__returns_empty_when_empty_args :Tests {
    is_deeply(
        filter([]),
        [],
    );
}

sub filter__returns_empty_when_not_found_in_array {
    is_deeply(
        filter(sub { $_[0] > 100}, [1,2,3,4,5]),
        [],
    );
}

sub filter__returns_multi_items_that_match_predicate {
    is_deeply(
        filter(sub { $_[0] > 2}, [1,2,3,4,5]),
        [3,4,5]
    );
}


sub drop__returns_empty_array_when_empty_array :Tests {
    is_deeply(drop([]), []);
}

sub drop__returns_empty_array_when_args_undef :Tests {
    is_deeply(drop(), []);
}

sub drop__returns_empty_array_when_incomplete_args :Tests {
    is_deeply(drop([], 1), []);
}

sub drop__drops_first_item_if_no_num_given :Tests {
    is_deeply(drop(["first", "second", "third", "fourth"]), ["second", "third", "fourth"]);
}

sub drop__drops_number_of_items_from_beginning :Tests {
    is_deeply(
        drop(["first","second", "third", "fourth", "fifth"], 2),
        ["third", "fourth", "fifth"]
    )
}

sub drop__drops_no_items_if_num_is_zero :Tests {
    is_deeply(
        drop(["first","second", "third", "fourth", "fifth"], 0),
        ["first","second", "third", "fourth", "fifth"],
    )
}

sub drop__returns_new_array :Tests {
    my $array = [1,2,3];

    ok($array != drop($array));
}


sub drop_right__returns_empty_array_when_empty_array :Tests {
    is_deeply(drop_right([]), []);
}

sub drop_right__returns_empty_array_when_args_undef :Tests {
    is_deeply(drop_right(), []);
}

sub drop_right__returns_empty_array_when_incomplete_args :Tests {
    is_deeply(drop_right([], 2), []);
}

sub drop_right__drops_last_item_if_no_num_given :Tests {
    is_deeply(drop_right([1,2,3,4,5,6,7]), [1,2,3,4,5,6]);
}

sub drop_right__drops_item_if_num_given :Tests {
    is_deeply(drop_right([1,2,3,4,5,6,7], 1), [1,2,3,4,5,6]);
}

sub drop_right__drops_multi_items_from_end :Tests {
    is_deeply(drop_right([1,2,3,4,5,6,7], 2), [1,2,3,4,5]);
}

sub drop_right__returns_new_array :Tests {
    my $array = [1,2,3];

    ok($array != drop_right($array));
}


sub take__returns_empty_array_when_empty_array :Tests {
    is_deeply(take([]), []);
}

sub take__returns_empty_array_when_args_undef :Tests {
    is_deeply(take(), []);
}

sub take__returns_empty_array_when_incomplete_args :Tests {
    is_deeply(take([], 2), []);
}

sub take__returns_first_item_from_array_default :Tests {
    is_deeply(take([1,2,3,4,5,6,7]), [1]);
}

sub take__returns_num_of_items_from_array :Tests {
    is_deeply(take([1,2,3,4,5,6,7], 1), [1])
}

sub take__multi_items_from_array :Tests {
    is_deeply(take([1,2,3,4,5,6,7], 2), [1,2])
}

sub take__returns_new_array :Tests {
    my $array = [];
    ok($array != take($array))
}


sub take_right__returns_empty_array_when_empty_array :Tests {
    is_deeply(take_right([]), []);
}

sub take_right__returns_empty_array_when_args_undef :Tests {
    is_deeply(take_right(), []);
}

sub take_right__returns_empty_array_when_incomplete_args :Tests {
    is_deeply(take_right([], 1), []);
}

sub take_right__returns__last_item_if_no_num_given :Tests {
    is_deeply(take_right([1,2,3,4,5,6,7]), [7])
}

sub take_right__returns_num_of_items_from_array :Tests {
    is_deeply(take_right([1,2,3,4,5,6,7], 1), [7]);
}

sub take_right__returns_multi_items_from_array :Tests {
    is_deeply(take_right([1,2,3,4,5,6,7], 3), [5,6,7]);
}

sub take_right__returns_new_array :Tests {
    my $array = [];
    ok($array != take($array))
}


sub assoc__returns_original_array_when_no_args :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7]), [1,2,3,4,5,6,7]);
}

sub assoc__adds_undef_when_item_explicit_undef :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7], 0, undef), [undef,2,3,4,5,6,7]);
}

sub assoc__adds_undef_when_item_implicit_undef :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7], 0), [undef,2,3,4,5,6,7]);
}

sub assoc__returns_new_array_with_item_at_idx :Tests {
    is_deeply(assoc([1,2,3,4,5,6,7], 0, "item"), ["item",2,3,4,5,6,7]);
}

sub assoc__returns_new_array_with_item_at_diff_indx :Tests {
    is_deeply(assoc([1,2,3], 1, "item"), [1,"item",3]);
}

sub assoc__returns_new_array :Tests {
    my $array = [1,2,3];
    ok(assoc([1,2,3], 1, "item") != $array);
}

sub assoc__returns_new_hash_with_item_at_key :Tests {
    is_deeply(
        assoc({ key => 'foobar' }, 'key', 'item'),
        { key => 'item' }
    );
}

sub assoc__returns_new_hash_multi_item_at_key :Tests {
    is_deeply(
        assoc({ key => 'foobar', other => 'value'}, 'key', 'item'),
        { key => 'item' , other => 'value'}
    );
}

sub assoc__returns_new_hash :Tests {
    my $hash = { key => 'value' };
    ok(assoc($hash, 'key', 'newValue') != $hash);
}


sub chain__accepts_expression_as_first_arg :Tests {
    my $addThree = sub { (shift) + 3 };

    my $result = chain(
        100,
        $addThree,
    );

    is($result, 103);
}

sub chain__accepts_func_as_first_arg :Tests {
    my $addThree = sub { (shift) + 3 };

    my $result = chain(
        sub { 100 },
        $addThree,
    );

    is($result, 103);
}

sub chain__accepts_anon_func :Tests {
    my $result = chain(
        100,
        sub { (shift) + 3 },
    );

    is($result, 103);
}

sub flatten__returns_empty_array_when_empty_array :Tests {
    is_deeply(flatten([]), []);
}

sub flatten__returns_empty_array_when_args_undef :Tests {
    is_deeply(flatten(), []);
}

sub flatten__returns_array_if_already_flat :Tests {
    is_deeply(flatten([1,2,3]), [1,2,3]);
}

sub flatten__returns_flattened_array :Tests {
    is_deeply(flatten([[1], 2, [3]]), [1,2,3]);
}

sub flatten__returns_single_level_flattened :Tests {
    is_deeply(flatten([[1], 2, [[3]]]), [1,2,[3]]);
}


sub subarray__returns_empty_array_if_args_undef :Tests {
    is_deeply(subarray(), []);
}

sub subarray__returns_orignal_array_if_incomplete_args :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7]), [1,2,3,4,5,6,7]);
}

sub subarray__returns_remaining_array_from_start_idx :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7], 3), [4,5,6,7]);
}

sub subarray__returns_items_between_idxs_non_inclusive_end :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7], 3,5), [4,5]);
}

#TODO Expected behavior here? check
sub subarray__returns_empty_array_when_start_end_same :Tests {
    is_deeply(subarray([1,2,3,4,5,6,7], 3,3), []);
}

sub subarray__returns_new_array {
    my $array = [1,2,3];

    ok($array != subarray($array, 1))
}


sub first__returns_undefined_if_no_args :Tests {
    is(first(), undef);
}

sub first__returns_first_item_in_list_of_one :Tests {
    is(first([1]), 1);
}

sub first__returns_first_item_in_list_of_many_items :Tests {
    is(first([1,2,3,4]), 1);
}


sub latest__returns_undefined_if_no_args :Tests {
    is(latest(), undef);
}

sub latest__returns_last_item_in_list_of_one :Tests {
    is(latest([1]), 1);
}

sub latest__returns_last_item_in_list_of_many_items :Tests {
    is(latest(["item", "another", "lastItem"]), "lastItem");
}

sub inc__throws_warning_if_non_num_as_arg :Tests {

    local $SIG{__WARN__} = sub {
        die shift;
    };

    eval { inc("string") };

    like($@, qr/isn't numeric in/);
}

sub inc__returns_num_plus_one :Tests {
    is(inc(100), 101);
}


sub dec__throws_warning_if_non_num_as_arg :Tests {

    local $SIG{__WARN__} = sub {
        die shift;
    };

    eval{ dec("string") };

    like($@, qr/isn't numeric in/);
}

sub dec__returns_num_minus_one :Tests {
    is(dec(100), 99);
}

sub dec__returns_num_minus_one_when_zero :Tests {
    is(dec(0), -1);
}

__PACKAGE__->runtests;
