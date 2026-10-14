#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use State::Store;

# The C ABI: the table has a stable address, the selftest walks every entry
# in C with every answer checked, and the store C built is a store Perl can
# use.

my $p = State::Store::_abi_ptr();
ok($p, '_abi_ptr returns a non-zero address');
is($p, State::Store::_abi_ptr(), 'and the same one every call');
like($p, qr/^\d+$/, 'and an unsigned integer');
is(State::Store::_abi_version(), 1, 'the table is version 1');

my $blocks = State::Store::_live_blocks();
my $hamt   = HAMT::_live_blocks();
{
    my ($step, $st) = State::Store::_abi_selftest();
    is($step, 0, 'every entry in the table answered as its declaration says')
        or diag("check number $step in include/store/store_abi_selftest.h failed");

    SKIP: {
        skip 'the selftest did not finish', 9 if $step;
        isa_ok($st, 'State::Store', 'the store C built');
        is($st->current, 1000, 'holds the last value C set');
        is($st->history_limit, 3, 'with the limit C set');
        is($st->undo_count, 3, 'and that many steps');
        is($st->watchers, 0, 'the watcher C added and removed is gone');
        is($st->validator, undef, 'and so is the validator');
        is(scalar($st->checkpoints), 0, 'and the checkpoint');
        ok(!$st->in_txn, 'and no transaction is open');
        $st->undo;
        is($st->current, 41, 'and Perl can undo what C did');
    }
}
is(State::Store::_live_blocks(), $blocks, 'once that store is gone, this library holds nothing it did not');
is(HAMT::_live_blocks(), $hamt, 'and nor does HAMT');

for (1 .. 50) { my ($step) = State::Store::_abi_selftest(); }
is(State::Store::_live_blocks(), $blocks, 'nor after fifty more runs');

done_testing;
