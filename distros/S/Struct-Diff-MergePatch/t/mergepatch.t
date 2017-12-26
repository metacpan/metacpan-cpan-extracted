#!perl -T

use strict;
use warnings FATAL => 'all';

use Clone qw(clone);
use Data::Dumper;
use Struct::Diff;
use Struct::Diff::MergePatch qw(diff patch);
use Test::More;

sub run_tests {
    for my $t (@_) {
        my $st = clone($t);

        my $diff = diff($st->{a}, $st->{b});

        is_deeply($st->{diff}, $diff, "Diff: $st->{name}") ||
            diag scmp($st->{diff}, $diff);

        subtest $st->{name} . "(patch)" => sub {
            patch($st->{a}, $diff);

            is_deeply($st->{a}, $st->{b}, "Patch: $st->{name}") ||
                diag scmp($st->{a}, $st->{b});

            is_deeply($st->{diff}, $t->{diff}, "Diff mangled $st->{name}") ||
                diag scmp($st->{diff}, $t->{diff});
        }
    }
}

sub scmp($$) {
    return "GOT: " . sdump(shift) . ";\nEXP: " . sdump(shift) . ";";
}

sub sdump($) {
    return Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
}

my @TESTS = (
    {
        a       => {},
        b       => {},
        name    => 'empty_hash_vs_empty_hash',
        diff    => {},
    },
    {
        a       => [],
        b       => {},
        name    => 'empty_list_vs_empty_hash',
        diff    => {},
    },
    {
        a       => {},
        b       => [],
        name    => 'empty_hash_vs_empty_list',
        diff    => [],
    },
    {
        a       => [],
        b       => undef,
        name    => 'empty_list_vs_undef',
        diff    => undef,
    },
    {
        a       => {},
        b       => undef,
        name    => 'empty_hash_vs_undef',
        diff    => undef,
    },
    {
        a       => undef,
        b       => {},
        name    => 'undef_vs_empty_hash',
        diff    => {},
    },
    {
        a       => undef,
        b       => [],
        name    => 'undef_vs_empty_list',
        diff    => [],
    },
    {
        a       => {one => {two => 2, three => 3, four => [0,1,2,3], five => 5}},
        b       => {one => {two => 7, three => 3, four => [1,2,3],   six  => 6}},
        name    => 'deep_complex_test',
        diff    => {one => {five => undef,four => [1,2,3],six => 6,two => 7}},
    },
    {
        a       => {a => 'b'},
        b       => {a => 'c'},
        name    => 'hash_value_changed',
        diff    => {a => "c"},
    },
    {
        a       => {a => 'b'},
        b       => {a => 'b', b => 'c'},
        name    => 'hash_key_added',
        diff    => {b => 'c'},
    },
    {
        a       => {a => 'b'},
        b       => {},
        name    => 'hash_become_empty',
        diff    => {a => undef},
    },
    {
        a       => {a => 'b', b => 'c'},
        b       => {b => 'c'},
        name    => 'hash_key_removed',
        diff    => {a => undef},
    },
    {
        a       => {a => ['b']},
        b       => {a => 'c'},
        name    => 'hash_key_value_type_changed_from_scalar_to_list',
        diff    => {a => 'c'},
    },
    {
        a       => {a => 'c'},
        b       => {a => ['b']},
        name    => 'hash_key_value_type_changed_from_list_to_scalar',
        diff    => {a => ['b']},
    },
    {
        a       => {a => {b => 'c'}},
        b       => {a => {b => 'd'}},
        name    => 'subhash_value_changed',
        diff    => {a => {b => 'd'}},
    },
    {
        a       => {a => {b => 'c'}},
        b       => {a => [1]},
        name    => 'hash_key_value_type_changed_from_hash_to_list',
        diff    => {a => [1]},
    },
    {
        a       => ['a','b'],
        b       => ['c','d'],
        name    => 'all_list_items_changed',
        diff    => ['c','d'],
    },
    {
        a       => {a => 'b'},
        b       => ['c'],
        name    => 'hash_vs_list',
        diff    => ['c'],
    },
    {
        a       => {a => 'foo'},
        b       => undef,
        name    => 'hash_vs_undef',
        diff    => undef,
    },
    {
        a       => {a => 'foo'},
        b       => 'bar',
        name    => 'hash_vs_scalar',
        diff    => 'bar',
    },
    {
        a       => {e => undef},
        b       => {a => 1},
        name    => 'undefs_as_main_struct_values',
        diff    => {a => 1, e => undef},
    },
);

run_tests(@TESTS);

my $target  = [1,2];
my $patch   = {a => 'b', c => undef};
patch($target, $patch);
my $expected = {a => 'b'};
is_deeply($target, $expected) || diag scmp($target, $expected);

$target     = {};
$patch      = {a => {b => {c => undef}}};
patch($target, $patch);
$expected   = {a => {b => {}}};
is_deeply($target, $expected) || diag scmp($target, $expected);

is_deeply(
    diff(Struct::Diff::diff({a => 1}, {b => 2})),
    {a => undef, b => 2},
    'diff convert mode'
);

done_testing(@TESTS * 2 + 3);
