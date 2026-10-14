#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The module loads, and it has found HAMT twice over: the header when it was
# built and the table when it was loaded. Everything later leans on both.

use_ok('State::Store') or BAIL_OUT('State::Store does not load');

ok(defined $State::Store::VERSION, 'State::Store has a version');
like($State::Store::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

ok($INC{'HAMT.pm'}, 'loading it loads HAMT');

# The XS bundle is loaded, which a pure-Perl stub would pass without.
can_ok('State::Store', '_hamt_abi_version');

my $built = State::Store::_hamt_abi_built();
my $found = State::Store::_hamt_abi_version();
cmp_ok($built, '>=', 1, 'it was compiled against a version of HAMT\'s table');
cmp_ok($found, '>=', $built, 'and the table it found is that version or a later one');
is($found, HAMT::_abi_version(), 'which is the table HAMT says it has');

# A table that resolved is one that can be called.
{
    my ($n, $last, $bad) = State::Store::_hamt_roundtrip();
    is($n, 0, 'a vector made through the table starts empty');
    is($last, undef, 'with no last value');
    is($bad, 0, 'and well formed');

    ($n, $last, $bad) = State::Store::_hamt_roundtrip(1 .. 100);
    is($n, 100, 'a hundred pushes through the table are a hundred values');
    is($last, 100, 'the last of them the last pushed');
    is($bad, 0, 'in a vector HAMT calls well formed');

    my $blocks = HAMT::_live_blocks();
    State::Store::_hamt_roundtrip(map { "v$_" } 1 .. 5000) for 1 .. 3;
    is(HAMT::_live_blocks(), $blocks, 'and given up, it leaves nothing allocated in HAMT');

    my $ref = [1, 2, 3];
    ($n, $last) = State::Store::_hamt_roundtrip('a', $ref);
    is($last, $ref, 'a reference goes in and comes out the same reference');
}

is(State::Store::_live_blocks(), 0, 'the library holds no blocks of its own yet');

diag("Testing State::Store $State::Store::VERSION on HAMT $HAMT::VERSION (C ABI $found), Perl $], $^X");

done_testing;
