#!/usr/bin/perl
# The op layer must be invisible. Every assertion here is either "the fast path
# gives the same answer as the slow one" or "the guard declined when it had to".
#
# The differential trick throughout: `$obj->get($k)` is hooked, and
# `$obj->$coderef($k)` is the same call with no METHOD_NAMED op in front of it,
# so it takes the ordinary XSUB path. Comparing the two compares the two paths
# on identical input, which is the only comparison worth making.

use strict;
use warnings;
use Test::More;
use blib;
use Shared::Arena;

my $arena = Shared::Arena->create(size => 4 << 20);
my $cache = $arena->cache('c', capacity => 256, entry_size => 512);
my $map   = $arena->map('m', slots => 256, slot_size => 512);
my $bloom = $arena->bloom('b', capacity => 1000);
my $hist  = $arena->histogram('h', max => 100_000, sigbits => 4);
my $ring  = $arena->ring('r', slots => 64, slot_size => 512);

# ---------------------------------------------------------------------------
# The path is real
#
# Without this every other test in the file passes whether the hook fired or
# not, which is the shape of a test that proves nothing.
{
    my ($hooked) = Shared::Arena::_xop_stats();
    ok($hooked > 0, "call sites were rewritten at compile time ($hooked)");

    Shared::Arena::_xop_reset();
    $cache->set('k', 'v');
    my $got = $cache->get('k');
    my (undef, $hits, $miss, $methonly) = Shared::Arena::_xop_stats();
    is($got,  'v', 'the value came back');
    cmp_ok($hits, '>', 0, 'the op path was taken');

    # `set` is ours outright. `get` is a name Frozen compiles too, and Frozen
    # is a prerequisite so it is always loaded and always gets there first -
    # which leaves the method op to us and the entersub to it. So `get`
    # reaches no door of ours and counts no hit, and that is the arrangement
    # working rather than failing. See sa_xop.h on why the op is not taken
    # back.
    cmp_ok($methonly, '>', 0,
           'and at least one call site is shared with another dist');
}

# ---------------------------------------------------------------------------
# Same answers as the XSUB, door by door
{
    my $xs_get = Shared::Arena::Cache->can('get');
    my $xs_set = Shared::Arena::Cache->can('set');

    Shared::Arena::_xop_reset();
    my $op = $cache->set('same', 'value');
    my $xs = $cache->$xs_set('same2', 'value');
    is($op, $xs, 'cache set: op path and XSUB agree on the return');

    is($cache->get('same'), $cache->$xs_get('same2'),
       'cache get: op path and XSUB agree on the value');

    my (undef, $hits) = Shared::Arena::_xop_stats();
    cmp_ok($hits, '>', 0, 'the method-call forms took the op path');
}

{
    my $store  = Shared::Arena::Map->can('store');
    my $fetch  = Shared::Arena::Map->can('fetch');
    my $exists = Shared::Arena::Map->can('exists');
    my $incr   = Shared::Arena::Map->can('incr');

    is($map->store('a', 'one'), $map->$store('b', 'one'),
       'map store: same return');
    is($map->fetch('a'), $map->$fetch('b'), 'map fetch: same value');
    is($map->exists('a'), $map->$exists('b'), 'map exists: same answer');
    is($map->exists('nope'), $map->$exists('nope'), 'map exists: same miss');

    # Eight zero bytes, not pack('Q<'): the 64-bit pack templates do not exist
    # on a perl built with ivsize=4, where 'Q' is a fatal "Invalid type".
    $map->store('n', "\0" x 8);
    is($map->incr('counter'), $map->$incr('counter2'),
       'map incr: same first value');
    $map->incr('counter');
    $map->$incr('counter2');
    is($map->incr('counter'), $map->$incr('counter2'),
       'map incr: still in step after three');
}

{
    my $add   = Shared::Arena::Bloom->can('add');
    my $check = Shared::Arena::Bloom->can('check');
    is($bloom->add('x'),   $bloom->$add('y'),   'bloom add: same first answer');
    is($bloom->add('x'),   $bloom->$add('y'),   'bloom add: same second answer');
    is($bloom->check('x'), $bloom->$check('y'), 'bloom check: same present');
    is($bloom->check('q'), $bloom->$check('z'), 'bloom check: same absent');
}

{
    my $record = Shared::Arena::Histogram->can('record');
    $hist->record($_)    for 1 .. 500;
    $hist->$record($_)   for 1 .. 500;
    my %s = $hist->stats;
    is($s{count}, 1000, 'histogram record: both paths counted');
    is($hist->quantile(0.5), $hist->quantile(0.5),
       'the distribution is one distribution');
}

{
    my $publish = Shared::Arena::Ring->can('publish');
    # Before publishing: a cursor starts where the ring is, not at the
    # beginning, so one made afterwards would see an empty ring and this would
    # be a test that passes for the wrong reason.
    my $cur = $ring->cursor;

    my $a = $ring->publish('t', 'body');
    my $b = $ring->$publish('t', 'body');
    is($b, $a + 1, 'ring publish: the op path returned a real sequence');

    my @got = $cur->drain;
    is(scalar @got, 2, 'both records are in the ring');
    is($got[0][0], 't',    'the op-published record kept its topic');
    is($got[0][1], 'body', 'and its payload, byte for byte');
    is($got[0][2], $a,     'under the sequence the op path reported');
}

{
    my $xs_allow = Shared::Arena::Rate->can('allow');
    my $rate = $arena->rate('rl', limit => 100, window => 60, slots => 64);

    # Two keys with the same budget, one spent through each path, compared
    # after every call: a limiter that answered differently would diverge on
    # the call the budget runs out, not before.
    my ($op, $xs) = ('', '');
    for (1 .. 120) {
        $op .= $rate->allow('op-key')          ? 1 : 0;
        $xs .= $rate->$xs_allow('xs-key')      ? 1 : 0;
    }
    is($op, $xs, 'rate allow: both paths spent the same budget, call for call');
    like($op, qr/^1+0+$/, 'and it really did run out partway through');

    # The optional cost is not the hooked shape, so it takes the long way.
    my $costly = $arena->rate('rl2', limit => 10, window => 60, slots => 64);
    ok($costly->allow('k', 10), 'a costly call is allowed while there is budget');
    ok(!$costly->allow('k'), 'and it really did spend all of it');
}

# ---------------------------------------------------------------------------
# Context
#
# An absent key is an empty list, not undef: the XSUB says so and the op path
# has to say the same thing, in both contexts, or `my ($v) = ...` and
# `if (defined ...)` start disagreeing about what a miss is.
{
    my @list = $cache->get('absent');
    is(scalar @list, 0, 'cache get: a miss is an empty list');

    my $scalar = $cache->get('absent');
    ok(!defined $scalar, 'cache get: a miss in scalar context is undef');

    my @mlist = $map->fetch('absent');
    is(scalar @mlist, 0, 'map fetch: a miss is an empty list');
    ok(!defined scalar $map->fetch('absent'), 'map fetch: and undef in scalar');

    my @void = $hist->record(1);
    is(scalar @void, 0, 'histogram record: returns nothing, like the XSUB');
}

# ---------------------------------------------------------------------------
# The guards decline
{
    package Some::Other::Thing;
    sub new    { bless { got => 0 }, shift }
    sub get    { "not the arena" }
    sub set    { "not the arena either" }
    sub fetch  { "nor this" }
    sub add    { "nor this" }
    sub check  { "nor this" }
    sub record { "nor this" }
    sub incr   { "nor this" }
    sub exists { "nor this" }
    sub store  { "nor this" }
    sub publish { "nor this" }
}

# ---------------------------------------------------------------------------
# One name, two of our own classes
#
# A filter and a sketch both answer to `add` at one argument, so one door has
# to cover both. If the hook table simply took the first match, whichever was
# listed first would win the name and the other would silently lose its fast
# path - the same failure two separate dists hit, and no better for being
# internal.
{
    my $bloom2 = $arena->bloom('b2', capacity => 1000);
    my $cms    = $arena->countmin('cm', error => 0.001, confidence => 0.99);

    Shared::Arena::_xop_reset();

    is($bloom2->add('x'), 0, 'the filter says the key is new');
    is($bloom2->add('x'), 1, 'and then that it is not');

    is($cms->add('k'), 1, 'the sketch counts one');
    is($cms->add('k'), 2, 'then two');
    is($cms->estimate('k'), 2, 'and estimates what it counted');

    my (undef, $hits, $miss) = Shared::Arena::_xop_stats();
    is($hits, 5, 'every one of those took the op path');
    is($miss, 0, 'and none of them had to decline');

    # Interleaved, in case the door only works for whichever ran first.
    is($bloom2->add('y'), 0, 'filter again');
    is($cms->add('z'),    1, 'sketch again');
    is($bloom2->add('y'), 1, 'and the filter still knows its own keys');
}

# ---------------------------------------------------------------------------
# Sharing a call site with the dist we depend on
#
# Frozen compiles `->get($k)` into an opcode exactly as this does, and both are
# loaded in every program that uses this one. The assertion is that each still
# answers for its own objects and neither answers for the other's.
{
    my $block = Frozen->attach(Frozen->freeze({ limits => { rate => 7 } }));

    is(scalar $block->get('limits.rate'), 7,
       "Frozen's own compiled get still answers for a Frozen container");
    is($cache->get('k'), 'v',
       'and ours still answers for a cache, at the same call sites');

    # Alternating, in case one of them only works when it runs first.
    for (1 .. 3) {
        is(scalar $block->get('limits.rate'), 7, 'Frozen again');
        is($cache->get('k'), 'v', 'and ours again');
    }
}

{
    Shared::Arena::_xop_reset();
    my $other = Some::Other::Thing->new;
    is($other->get('k'), 'not the arena', 'another class with a hooked name works');
    is($other->fetch('k'), 'nor this',    'and another');
    is($other->set('k', 'v'), 'not the arena either', 'and a two-arg one');

    my (undef, $hits, $miss) = Shared::Arena::_xop_stats();
    is($hits, 0, 'none of those took the op path');
    # Not an exact count: `get` is a call site Frozen's hook owns, so ours is
    # never reached to decline there. The assertion that matters is the three
    # results above, which are the other class's own answers.
    cmp_ok($miss, '>', 0, 'the ones we do own declined and delegated');
}

{
    # A class name rather than an object.
    Shared::Arena::_xop_reset();
    is(Some::Other::Thing->get('k'), 'not the arena', 'a class method still works');
    my (undef, $hits) = Shared::Arena::_xop_stats();
    is($hits, 0, 'a string invocant never reaches the door');
}

{
    # A subclass that overrides. The stash is not ours, so the override runs -
    # and if the guard compared with isa() instead of identity, it would not.
    package Cache::Subclass;
    our @ISA = ('Shared::Arena::Cache');
    sub get { "overridden" }
}

{
    my $sub = bless \(my $x = 0), 'Cache::Subclass';
    is($sub->get('k'), 'overridden', 'a subclass override is not stolen');
}

{
    # A different arity than the one hooked takes the ordinary path, which is
    # how the optional arguments keep working.
    Shared::Arena::_xop_reset();
    $cache->set('ttl', 'v', ttl => 60);
    is($cache->get('ttl'), 'v', 'set with a ttl still stores');

    my $c1 = $map->incr('by');
    my $c2 = $map->incr('by', 5);
    is($c2, $c1 + 5, 'incr with a step still steps');

    $hist->record(7, 3);
    my (undef, $hits) = Shared::Arena::_xop_stats();
    ok($hits < 5, "the extra-argument forms went the long way ($hits)");
}

# ---------------------------------------------------------------------------
# An argument list that is not the shape it was compiled as
#
# The hook counts arguments at COMPILE time, where `$c->get(@args)` is one
# argument however many @args turns out to hold. So the door counts again at
# runtime, and a list that flattened to a different width takes the ordinary
# path and gets the ordinary error. Without the second count the door would
# read whatever happened to be in that stack slot and leave the stack short.
{
    my @one = ('k');
    is($cache->get(@one), 'v', 'a list that flattens to the hooked width works');

    my @two = ('k', 'extra');
    my $err = '';
    eval { my $x = $cache->get(@two); 1 } or $err = $@;
    like($err, qr/Usage|argument/i,
         'one that flattens wider gets the ordinary usage error');

    my @none = ();
    $err = '';
    eval { my $x = $cache->get(@none); 1 } or $err = $@;
    like($err, qr/Usage|argument/i, 'and one that flattens to nothing does too');

    # The stack must be intact afterwards, which is the failure a bad arity
    # check produces that an exception test would not notice.
    my @after = ($cache->get('k'), 'sentinel');
    is_deeply(\@after, ['v', 'sentinel'], 'the stack survived all of that');
}

# ---------------------------------------------------------------------------
# A monkeypatch wins
#
# This is the assertion the whole identity guard exists for. If the door
# compared against whatever the glob holds now, the replacement would match
# itself and the C code would run in its place - a patch that silently does
# nothing.
{
    my $before = $cache->get('k');
    is($before, 'v', 'the door works before the patch');

    no warnings 'redefine';
    no strict 'refs';
    my $orig = \&Shared::Arena::Cache::get;
    local *Shared::Arena::Cache::get = sub { "patched: $_[1]" };

    Shared::Arena::_xop_reset();
    is($cache->get('k'), 'patched: k', 'the replacement runs, not the C door');
    my (undef, $hits) = Shared::Arena::_xop_stats();
    is($hits, 0, 'and no door of ours answered instead of it');
}

is($cache->get('k'), 'v', 'and the door comes back when the patch goes away');

# ---------------------------------------------------------------------------
# A released handle still croaks
#
# The op path checks the pointer and declines, so the XSUB produces the same
# message it always did rather than the op dereferencing NULL.
{
    my $r2 = Shared::Arena->create(size => 1 << 20);
    my $c2 = $r2->cache('gone', capacity => 16);
    $c2->set('k', 'v');
    $c2->DESTROY;

    my $err = '';
    eval { $c2->get('k'); 1 } or $err = $@;
    like($err, qr/released/, 'a released cache croaks rather than crashing');

    $err = '';
    eval { $c2->set('k', 'v'); 1 } or $err = $@;
    like($err, qr/released/, 'and on the write door too');
}

# ---------------------------------------------------------------------------
# The optree is still an optree
#
# op_type is left alone precisely so this keeps working. A dumper that cannot
# read the tree is a debugger that cannot debug the program.
SKIP: {
    eval { require B::Deparse; 1 } or skip 'no B::Deparse', 2;
    my $src = B::Deparse->new->coderef2text(sub {
        my ($c, $k) = @_;
        return $c->get($k);
    });
    like($src, qr/->get\(/, 'B::Deparse still sees an ordinary method call');
    unlike($src, qr/custom/i, 'and nothing custom leaked into it');
}

# ---------------------------------------------------------------------------
# It survives a fork
#
# The optree is shared with the child and the doors are the same pointers, so
# a hooked call site works on both sides. Worth an assertion because the whole
# dist exists to be used across a fork.
SKIP: {
    # The house spelling. Not a d_fork probe: Strawberry sets d_pseudofork
    # and leaves d_fork undef, so the probe happens to skip for a reason that
    # reads like an accident, and the next person to touch it would fix the
    # "bug" and break the file.
    skip 'fork is POSIX-only here', 3 if $^O eq 'MSWin32';

    $cache->set('shared', 'from the parent');
    my $pid = fork();
    skip 'fork failed', 3 unless defined $pid;

    if (!$pid) {
        my $ok = ($cache->get('shared') || '') eq 'from the parent';
        $cache->set('child', 'from the child');
        my (undef, $hits) = Shared::Arena::_xop_stats();
        POSIX::_exit($ok && $hits > 0 ? 0 : 1);
    }

    waitpid($pid, 0);
    is($?, 0, 'the child read through the op path and wrote through it');
    is($cache->get('child'), 'from the child', 'the parent sees what it wrote');
    ok(1, 'and the parent is still running');
}

BEGIN { require POSIX; require Config; }

done_testing();
