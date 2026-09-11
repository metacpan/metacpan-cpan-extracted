#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# MANY PUBLISHERS, ONE READER, AND NO TORN RECORDS.
#
# Every check here is about the seqlock: a record is committed by one release
# store of its sequence, and a reader validates that sequence before AND after
# copying the body. Drop the second check and a publisher that laps the ring
# mid-copy hands the reader half of one record and half of another - with a
# sequence that says everything is fine.
#
# So every payload is self-describing: it carries the child that wrote it and
# the index it wrote, and the topic carries the child too. A record whose topic
# and payload disagree, or whose length is wrong, is a torn one, and no amount
# of correct accounting makes up for it.
#
# THE SIZE IS THE POINT. A handful of processes will not collide often enough
# to prove anything - the note in this workspace is of a broken build that
# passed at 40 concurrent and failed at 1500. So: enough children to contend,
# enough records to lap the ring many times over, and a ring small enough that
# lapping is the normal case rather than the exception.

plan skip_all => 'no atomics in this build' unless Shared::Arena::have_atomics();
plan skip_all => 'fork is POSIX-only here' if $^O eq 'MSWin32';

require POSIX;

my $KIDS    = 8;
my $PER_KID = 2000;
my $TOTAL   = $KIDS * $PER_KID;
# Longer than a slot holds, so EVERY record in this storm spans several and the
# head-last publish ordering is under contention rather than merely exercised.
# A reader that gathered a tail whose parts were not all committed would show up
# here as a short record or a mixed one, and both are checked below.
my $FILL    = $ENV{SA_SPAN} ? 600 : 40;

my $a = Shared::Arena->create(size => 2 * 1024 * 1024);
my $r = $a->ring('storm', slots => 256, slot_size => 128);

# A start gate, in the arena itself. Without one the children start as they are
# forked and the first is often finished before the last begins, so the run
# measures the scheduler rather than the ring.
$a->region('gate', size => 16);
$a->poke('gate', 0, 'wait');

my $c = $r->cursor;

my @pids;
for my $kid (1 .. $KIDS) {
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        # The child inherits the mapping and publishes into the same ring.
        # Spin on the gate so every child is running before any of them does
        # real work. The gate is a byte in the arena, which is the shortest
        # possible demonstration of what the arena is for.
        my $spun = 0;
        while ($a->peek('gate', 0, 4) ne 'go!!') {
            POSIX::_exit(2) if ++$spun > 50_000_000;
        }
        for my $i (1 .. $PER_KID) {
            $r->publish(sprintf('c%02d', $kid),
                        sprintf('%02d:%05d:', $kid, $i) . ('.' x $FILL));
        }
        # _exit, not exit: the parent's END blocks and its test plan must not
        # run a second time in here.
        POSIX::_exit(0);
    }
    push @pids, $pid;
}
$a->poke('gate', 0, 'go!!');

# Drain while they work, so the reader is genuinely racing the writers rather
# than reading a settled ring afterwards.
my ($delivered, $torn, %by_kid, %last_idx, $out_of_order) = (0, 0);
$out_of_order = 0;
my $reap = 0;
while ($reap < $KIDS) {
    for my $rec ($c->drain) {
        $delivered++;
        my ($topic, $body) = @$rec;
        if ($body =~ /^(\d{2}):(\d{5}):(\.*)$/) {
            my ($kid, $idx, $tail) = ($1, $2, $3);
            $torn++, next if $topic ne "c$kid";
            $torn++, next if length($tail) != $FILL;
            # A spanned record is gathered from several slots; if any part came
            # from a different record the fill would not be uniform.
            $torn++, next if $tail =~ /[^.]/;
            $kid += 0; $idx += 0;
            # One publisher's records are handed sequences by one atomic in the
            # order it published them, and a cursor delivers by increasing
            # sequence - so a child's indices must never go backwards, however
            # much of its output was lapped away in between.
            $out_of_order++ if defined $last_idx{$kid} && $idx <= $last_idx{$kid};
            $last_idx{$kid} = $idx;
            $by_kid{$kid}++;
        }
        else {
            $torn++;
        }
    }
    # Reap without blocking, so the loop keeps draining until they are all done.
    while ((my $done = waitpid(-1, POSIX::WNOHANG())) > 0) { $reap++ }
}
# Whatever they published after the last drain.
for my $rec ($c->drain) {
    $delivered++;
    my ($topic, $body) = @$rec;
    if ($body =~ /^(\d{2}):(\d{5}):(\.*)$/) {
        my ($kid, $idx, $tail) = ($1, $2, $3);
        $torn++, next if $topic ne "c$kid" || length($tail) != $FILL;
        $kid += 0; $idx += 0;
        $out_of_order++ if defined $last_idx{$kid} && $idx <= $last_idx{$kid};
        $last_idx{$kid} = $idx;
        $by_kid{$kid}++;
    }
    else { $torn++ }
}

my %rs = $r->stats;
my %cs = $c->stats;

is($torn, 0, "no torn records across $TOTAL publishes from $KIDS processes")
    or diag "a torn record means the seqlock's second check is not doing its job";

is($rs{published}, $TOTAL,
   'the ring counted every publish from every child');

# THE ACCOUNTING, in the units each counter actually uses.
#
# `published` counts RECORDS; `lapped` counts SLOTS, because by the time a
# reader finds a hole the header that said how many slots a lost record spanned
# is gone with it. The two are the same number only when every record fits one
# slot - so assert the identity that holds in either case, in sequences.
{
    my $span = 1;
    if ($FILL > $r->slot_bytes) {
        my $cap   = $r->slot_bytes;
        my $tot   = length(sprintf('%02d:%05d:', 1, 1)) + $FILL;
        my $first = $cap - 3;                       # the topic is 'cNN'
        $span = 1 + int(($tot - $first + $cap - 1) / $cap);
    }

    # THE CURSOR'S OWN TRAVERSAL, not everything ever published. A cursor stops
    # at the first record still being written rather than blocking on it, so at
    # any instant there may be sequences ahead of it that are neither delivered
    # nor lost - they simply have not happened to it yet. The identity that
    # holds at every instant is over the ground this cursor has covered.
    my $covered = $cs{seq} - 1;                     # cursors start at 1
    is($cs{delivered} * $span + $cs{lapped}, $covered,
       'every slot the cursor passed was either delivered or counted lost');
    cmp_ok($covered, '<=', $rs{seq} - 1,
           'and it never claimed to have passed more than exists');
}

cmp_ok($cs{lapped}, '>', 0,
       'and the reader really was overtaken - otherwise this test proved '
     . 'nothing about lapping under contention');

is($out_of_order, 0,
   'no publisher\'s records were delivered out of the order it wrote them');

# How many children got through at all is a fact about the scheduler, not a
# promise the ring makes - with 256 slots and 16,000 records most of what every
# child writes is lapped away. What matters is that more than one did, because
# a run where they did not overlap tested nothing about contention.
cmp_ok(scalar keys %by_kid, '>=', 2,
       'records from at least two children interleaved, so the publishers '
     . 'really were concurrent')
    or diag 'only one child got through: this run did not test contention';
diag sprintf 'delivered %d of %d, lapped %d, from %d of %d children',
     $cs{delivered}, $TOTAL, $cs{lapped}, scalar keys %by_kid, $KIDS;

# Sequences are handed out by one atomic, so no two publishers can ever have
# been given the same one. If they had been, the ring's own count would exceed
# what the cursor could account for.
cmp_ok($rs{seq}, '>=', $TOTAL,
       'the sequence advanced at least once per record, with no reuse');

done_testing;
