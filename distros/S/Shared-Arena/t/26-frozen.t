#!/usr/bin/perl
# One structure, published once, read in place by everybody.

use strict;
use warnings;
use Test::More;
use blib;
use Shared::Arena;
use Config;

plan skip_all => 'no atomics in this build' unless Shared::Arena->have_atomics;

my $arena = Shared::Arena->create(size => 8 << 20);

# ---- nothing published yet -------------------------------------------------
{
    my $f = $arena->frozen('empty', size => 4096);
    my @v = $f->view;
    is(scalar @v, 0, 'no view before anything is published');
    ok(!defined scalar $f->view, 'and undef in scalar context');
    is($f->generation, 0, 'generation starts at zero');
}

# ---- a structure goes in and comes back ------------------------------------
{
    my $f = $arena->frozen('conf', size => 64 * 1024);
    my $data = {
        name     => 'app',
        port     => 5432,
        ratio    => 0.25,
        db       => { host => 'localhost', opts => { ssl => 1 } },
        routes   => [ '/', '/login', '/admin' ],
        empty    => {},
    };

    my $gen = $f->publish($data);
    is($gen, 1, 'the first publish is generation 1');

    my $v = $f->view or die 'no view';
    is($v->get('name'), 'app',  'a string came back');
    is($v->get('port'), 5432,   'and a number');
    cmp_ok(abs($v->get('ratio') - 0.25), '<', 1e-9, 'and a float');

    is($v->get('db.host'),      'localhost', 'a nested string by dotted path');
    is($v->get('db.opts.ssl'),  1,           'and one two levels down');
    is($v->get('db/host', '/'), 'localhost', 'and with a separator of its own');

    # find does no splitting at all, which is what a key with a dot in it
    # needs.
    is_deeply(scalar $v->find('db'), $data->{db}, 'find takes a whole key');

    is_deeply($v->get('routes'), [ '/', '/login', '/admin' ],
              'an array comes back whole');
    is_deeply($v->get('empty'), {}, 'and an empty hash is an empty hash');

    is_deeply([sort $v->keys], [sort keys %$data], 'the keys are the keys');
    is($v->count, scalar keys %$data, 'and the count agrees');

    ok($v->exists('db'),          'exists says yes to a key that is there');
    ok($v->exists('db.opts.ssl'), 'and to a dotted path');
    ok(!$v->exists('nope'),       'and no to one that is not');
    ok(!$v->exists('db.nope'),    'nor to a path that stops short');
    is(scalar(() = $v->get('nope')), 0, 'a missing key is an empty list');
    is(scalar(() = $v->get('db.nope')), 0, 'and so is a missing path');
    is(scalar(() = $v->get('nope.nope')), 0, 'and one that fails at the first step');

    is_deeply($v->inflate, $data, 'and the whole thing round trips');

    cmp_ok($v->verify, '>', 0, 'the block verifies structurally');
    cmp_ok($v->bytes,  '>', 0, 'and reports its size');
}

# ---- republishing ----------------------------------------------------------
{
    my $f = $arena->frozen('moving', size => 4096);
    is($f->publish({ n => 1 }), 1, 'generation 1');
    is($f->publish({ n => 2 }), 2, 'generation 2');
    is($f->publish({ n => 3 }), 3, 'generation 3');
    is($f->generation, 3, 'the tenant agrees');

    my $v = $f->view;
    is($v->get('n'), 3, 'a view opened now sees the newest block');
    is($v->generation, 3, 'and says which generation it is');
    ok($v->fresh, 'and it is fresh');
}

# ---- THE VIEW BORROWS, IT DOES NOT COPY ------------------------------------
#
# This is the assertion the whole tenant rests on, and the only way to make it
# is to change the bytes underneath a live view and watch the view change with
# them. A view that had copied would go on reporting what it copied.
#
# So: hold a view, then publish until the slots come round to the one it is
# reading. `slots` publishes is exactly one lap.
{
    my $f = $arena->frozen('borrowed', size => 4096, slots => 2);
    $f->publish({ mark => 'first' });

    my $v = $f->view;
    is($v->get('mark'), 'first', 'the view reads what was published');
    ok($v->fresh, 'and is fresh to begin with');

    $f->publish({ mark => 'second' });
    ok($v->fresh, 'still fresh after a publish into the OTHER slot');
    is($v->get('mark'), 'first', 'and still reading its own block');

    # One more, which comes back round to this view's slot.
    $f->publish({ mark => 'third' });
    ok(!$v->fresh, 'not fresh once the slots have come round');
    is($v->get('mark'), 'third',
       'and it is reading the new bytes - which is the proof it borrowed '
       . 'them rather than copying them');

    my $fresh = $f->view;
    ok($fresh->fresh, 'a view taken now is fresh');
    is($fresh->get('mark'), 'third', 'and reads the current block');
}

# ---- a block that does not fit is refused, not truncated -------------------
{
    my $f = $arena->frozen('small', size => 1024);
    ok(defined $f->publish({ a => 'x' }), 'a small block publishes');

    my $big = { map { ("key$_" => 'x' x 100) } 1 .. 200 };
    my $rc  = $f->publish($big);
    ok(!defined $rc, 'one that does not fit returns undef');

    my %s = $f->stats;
    is($s{refused}, 1, 'and is counted as refused');
    is($s{generation}, 1, 'the generation did not move');

    my $v = $f->view;
    is($v->get('a'), 'x', 'and the block that was there is untouched');
}

# ---- bytes from elsewhere --------------------------------------------------
{
    my $f = $arena->frozen('wire', size => 8192);
    my $block = Frozen->freeze({ from => 'the wire', n => [1, 2] });

    my $gen = $f->publish_bytes($block);
    is($gen, 1, 'a real block published straight from bytes');
    my $v = $f->view;
    is($v->get('from'), 'the wire', 'and reads back');

    my $err = '';
    eval { $f->publish_bytes('not a frozen block at all'); 1 } or $err = $@;
    ok($err, 'bytes that are not a block are refused');
    is($f->generation, 1, 'and nothing was published');

    # A block whose header is right and whose body is not: the header check
    # alone would let this through, which is why the structure is walked.
    my $mangled = $block;
    substr($mangled, length($mangled) - 8, 8) = "\xff" x 8;
    $err = '';
    eval { $f->publish_bytes($mangled); 1 } or $err = $@;
    ok($err, 'and so is a block whose structure does not hold together')
        or diag("published generation " . $f->generation);
}

# ---- the shape belongs to the region, not the caller -----------------------
{
    $arena->frozen('shaped', size => 4096, slots => 4);
    my $err = '';
    eval { $arena->frozen('shaped', size => 8192, slots => 4); 1 } or $err = $@;
    ok($err, 'a second caller asking for a different size is refused');
}

# ---- a released handle croaks rather than crashing -------------------------
{
    my $f = $arena->frozen('gone', size => 1024);
    $f->publish({ a => 1 });
    my $v = $f->view;
    $v->DESTROY;
    my $err = '';
    eval { $v->get('a'); 1 } or $err = $@;
    like($err, qr/view is gone/, 'a released view croaks');

    $f->DESTROY;
    $err = '';
    eval { $f->publish({ a => 1 }); 1 } or $err = $@;
    like($err, qr/released/, 'and a released tenant does too');
}

# ---- across a fork, which is the point -------------------------------------
#
# Skipped where fork is emulated with threads. A pseudo-process is a thread in
# THIS process, so POSIX::_exit in a child ends the whole test file: every
# assertion above passes, no plan is ever printed, and the harness calls that a
# FAIL. Shared-Arena 0.01 failed on Strawberry 5.42 for exactly this.
SKIP: {
    skip 'fork is POSIX-only here', 1 if $^O eq 'MSWin32';

    my $f = $arena->frozen('shared', size => 64 * 1024);
    $f->publish({
        db     => { host => 'db.internal', port => 5432 },
        flags  => { search => 1 },
        list   => [ 1 .. 20 ],
    });

    pipe(my $rd, my $wr) or die "pipe: $!";
    my @pid;
    for my $k (1 .. 3) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if (!$pid) {
            close $rd;
            my $v = $f->view;
            my $ok = $v
                  && $v->get('db.host') eq 'db.internal'
                  && $v->get('db.port') == 5432
                  && $v->get('flags.search') == 1
                  && @{ $v->get('list') } == 20
                  && $v->generation == 1;
            print {$wr} ($ok ? "ok\n" : "NOT ok\n");
            close $wr;
            POSIX::_exit(0);
        }
        push @pid, $pid;
    }
    close $wr;
    my @said = <$rd>;
    waitpid($_, 0) for @pid;
    chomp @said;
    is_deeply(\@said, [ ('ok') x 3 ],
              'three children read the block the parent published');
}

# ---- a child publishes and the parent sees it ------------------------------
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $f = $arena->frozen('upward', size => 4096);
    $f->publish({ who => 'parent' });

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $f->publish({ who => 'child' });
        POSIX::_exit(0);
    }
    waitpid($pid, 0);

    is($f->generation, 2, 'the parent sees the child\'s publish');
    is($f->view->get('who'), 'child', 'and reads what the child wrote');
}

# ---- and through a SECOND mapping of the same arena -------------------------
#
# The arena's cardinal rule is that nothing inside it is a pointer, and a block
# is only useful here because Frozen obeys the same rule. Two mappings at two
# addresses in one process is what makes a stray absolute pointer fail
# deterministically rather than only on an unrelated machine.
SKIP: {
    my $name = "sa-frozen-$$";
    my $a = Shared::Arena->create(name => $name, size => 1 << 20)
        or skip 'named regions unavailable', 3;
    my $b = Shared::Arena->attach($name)
        or skip 'named regions unavailable', 3;

    isnt($a->base, $b->base, 'the two mappings are at different addresses');

    my $fa = $a->frozen('x', size => 8192);
    my $fb = $b->frozen('x', size => 8192);

    $fa->publish({ deep => { deeper => 'found it' }, list => [ 'a', 'b' ] });

    my $v = $fb->view;
    is($v->get('deep.deeper'), 'found it',
       'a block published through one mapping reads through the other');
    is_deeply($v->get('list'), [ 'a', 'b' ], 'including its arrays');

    undef $fa; undef $fb; undef $v;
    Shared::Arena->destroy($name);
}

BEGIN { require POSIX }

done_testing();
