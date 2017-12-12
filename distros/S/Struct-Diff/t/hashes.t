#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More;

use lib "t";
use _common;

my $one;
my @TESTS = (
    {
        a       => {},
        b       => [],
        name    => 'empty_hash_vs_empty_list',
        diff    => {N => [],O => {}},
    },
    {
        a       => {},
        b       => {},
        name    => 'empty_hash_vs_empty_hash',
        diff    => {U => {}},
    },
    {
        a       => {},
        b       => {},
        name    => 'empty_hash_vs_empty_hash_noU',
        diff    => {},
        opts    => {noU => 1},
    },
    {
        a       => {},
        b       => {one => 1},
        name    => 'empty_hash_vs_hash_with_one_key',
        diff    => {D => {one => {A => 1}}},
    },
    {
        a       => {},
        b       => {one => 1},
        name    => 'empty_hash_vs_hash_with_one_key_noA',
        diff    => {},
        opts    => {noA => 1},
    },
    {
        a       => {one => 1},
        b       => {},
        name    => 'hashes_with_one_key_vs_empty_hash',
        diff    => {D => {one => {R => 1}}},
    },
    {
        a       => {one => 1},
        b       => {},
        name    => 'hashes_with_one_key_vs_empty_hash_noR',
        diff    => {},
        opts    => {noR => 1},
    },
    {
        a       => {one => {two => 2}},
        b       => {one => {}},
        name    => 'subhash_emptied',
        diff    => {D => {one => {D => {two => {R => 2}}}}},
    },
    {
        a       => {one => {two => 2}},
        b       => {one => {}},
        name    => 'subhash_emptied_noR',
        diff    => {},
        opts    => {noR => 1},
    },
    {
        a       => {one => {}},
        b       => {one => {two => 2}},
        name    => 'subhash_filled',
        diff    => {D => {one => {D => {two => {A => 2}}}}},
    },
    {
        a       => {one => {}},
        b       => {one => {two => 2}},
        name    => 'subhash_filled_noA',
        diff    => {},
        opts    => {noA => 1},
    },
    {
        a       => {one =>{two => {three => 3}}},
        b       => {one =>{two => {three => 3}}},
        name    => 'nested_hashes_with_one_equal_value',
        diff    => {U => {one => {two => {three => 3}}}},
    },
    {
        a       => {one =>{two => {three => 3}}},
        b       => {one =>{two => {three => 3}}},
        name    => 'nested_hashes_with_one_equal_value_noU',
        diff    => {},
        opts    => {noU => 1},
    },
    {
        a       => {one =>{two => {three => 3}}},
        b       => {one =>{two => {three => 4}}},
        name    => 'nested_hashes_with_one_different_value',
        diff    => {D => {one => {D => {two => {D => {three => {N => 4,O => 3}}}}}}},
    },
    {
        a       => {one => {two => 2}},
        b       => {one => {two => 2, three => 3}},
        name    => 'one_key_added_to_subhash',
        diff    => {D => {one => {D => {two => {U => 2}, three => {A => 3}}}}},
    },
    {
        a       => {one => {two => 2}},
        b       => {one => {two => 2, three => 3}},
        name    => 'one_key_added_to_subhash_noU',
        diff    => {D => {one => {D => {three => {A => 3}}}}},
        opts    => {noU => 1},
    },
    {
        a       => {one => {two => 2, three => 3}},
        b       => {one => {two => 2}},
        name    => 'one_key_removed_from_subhash',
        diff    => {D => {one => {D => {two => {U => 2}, three => {R => 3}}}}},
    },
    {
        a       => {one => {two => 2, three => 3}},
        b       => {one => {two => 2}},
        name    => 'one_key_removed_from_subhash_noU',
        diff    => {D => {one => {D => {three => {R => 3}}}}},
        opts    => {noU => 1},
    },
    {
        a       => {one => {two => {three => 3}}},
        b       => {},
        name    => 'deeply_nested_hash_vs_empty_hash',
        diff    => {D => {one => {R => {two => {three => 3}}}}},
    },
    {
        a       => {one => {two => {three => 3}}},
        b       => {},
        name    => 'deeply_nested_hash_vs_empty_hash_trimR',
        diff    => {D => {one => { R => undef } }},
        opts    => {trimR => 1},
    },
    {
        a       => {one => {two => {three => 3}}, four => 4},
        b       => {four => 4},
        name    => 'deeply_nested_subhash_removed_from_hash',
        diff    => {D => {one => {R => {two => {three => 3}}},four => {U => 4}}},
    },
    {
        a       => {one => {two => {three => 3}}, four => 4},
        b       => {four => 4},
        name    => 'deeply_nested_subhash_removed_from_hash_trimR',
        diff    => {D => {one => {R => undef},four => {U => 4}}},
        opts    => {trimR => 1},
    },
    {
        a       => {one => 1},
        b       => {one => 2},
        name    => 'hashes_with_one_different_value_noN',
        diff    => {D => {one => {O => 1}}},
        opts    => {noN => 1},
    },
    {
        a       => {one => 1},
        b       => {one => 2},
        name    => 'hashes_with_one_different_value_noO',
        diff    => {D => {one => {N => 2}}},
        opts    => {noO => 1},
    },
    {
        a       => $one = {one => 1},
        b       => $one,
        name    => 'same_ref_hashes',
        diff    => {U => {one => 1}},
        to_json => 0,
    },
    {
        a       => {one => 1, two => {nine => 9, ten => 10}, three => 3},
        b       => {one => 1, two => {nine => 8, ten => 10}, four => 4},
        name    => 'complex_hash',
        diff    => {
            D => {
                one   => {U => 1},
                two   => {D => {nine => {N => 8,O => 9},ten => {U => 10}}},
                three => {R => 3},
                four  => {A => 4}
            }
        },
    },
    {
        a       => {one => 1, two => {nine => 9, ten => 10}, three => 3},
        b       => {one => 1, two => {nine => 8, ten => 10}, four => 4},
        name    => 'complex_hash_noU',
        diff    => {
            D => {
                two => {D => {nine => {N => 8,O => 9}}},
                three => {R => 3},
                four => {A => 4}
            }
        },
        opts    => {noU => 1},
    },
);

run_batch_tests(@TESTS);

done_testing();
