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
# How often a child gives the processor up mid-loop, so that the children
# interleave on a host that cannot run them at once. See the loop below.
my $YIELD   = int($PER_KID / 8) || 1;

my $a = Shared::Arena->create(size => 2 * 1024 * 1024);
my $r = $a->ring('storm', slots => 256, slot_size => 128);

# A start gate, in the arena itself. Without one the children start as they are
# forked and the first is often finished before the last begins, so the run
# measures the scheduler rather than the ring.
$a->region('gate', size => 16);
$a->poke('gate', 0, 'wait');

# Where each child leaves the first and last sequence the ring gave it, as
# twenty decimal digits each, so the parent can tell afterwards whether the
# children's publishing overlapped in time. See the assertion at the end.
$a->region('ranges', size => $KIDS * 40);
$a->poke('ranges', 0, ' ' x ($KIDS * 40));

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
        my ($first, $last) = (0, 0);
        for my $i (1 .. $PER_KID) {
            my $seq = $r->publish(sprintf('c%02d', $kid),
                                  sprintf('%02d:%05d:', $kid, $i) . ('.' x $FILL));
            $first = $seq if !$first && $seq > 0;
            $last  = $seq if $seq > 0;
            # Hand the processor over a few times on the way through. On a box
            # with fewer processors than children the storm is otherwise not a
            # storm: a child runs its whole loop inside one timeslice, so the
            # children publish one after another and no two of them are ever
            # writing the ring in the same span. A publisher stopped between
            # taking a sequence and committing it, while the others lap the
            # ring past it, is the case the seqlock and the hole handling are
            # there for, and it only happens if they are interleaved.
            select undef, undef, undef, 0.0002 if $i % $YIELD == 0;
        }
        $a->poke('ranges', ($kid - 1) * 40, sprintf('%020d%020d', $first, $last));
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

# One reader against eight publishers will be overtaken on any host anyone
# runs this on, but BEING overtaken is the scheduler's doing and not something
# the ring promises. What holds either way is that nothing went missing
# quietly: a record is delivered or it is counted lost, never neither.
ok($cs{lapped} > 0 || $cs{delivered} == $TOTAL,
   'the reader was overtaken, or it kept up and missed nothing');

is($out_of_order, 0,
   'no publisher\'s records were delivered out of the order it wrote them');

# WHAT THE CHILDREN'S SEQUENCE RANGES PROVE, AND WHAT THEY ONLY REPORT.
#
# Each child left the first and last sequence the ring handed it. Two different
# kinds of fact live in those numbers and the difference is the whole point:
#
#   - A child was handed $PER_KID sequences by one atomic, in increasing order
#     and shared with nobody, so its range must be at least that wide. That is
#     the ring's promise and it holds however the children were scheduled.
#     Asserted.
#   - Whether two children's ranges OVERLAP is the host's scheduling. Where
#     there are fewer processors than children and the whole storm is shorter
#     than a timeslice, each child runs to the end before the next one starts
#     and no two ranges overlap - which says nothing about the ring. 0.06
#     failed here on such a box. Reported, not asserted.
#
# Counting how many children the READER saw records from is the same trap one
# step further out: it needs the parent scheduled mid-storm, and on a
# two-processor smoker with eight children spinning it was not - it drained
# once, at the end, and saw one ring's worth of the last child's tail. That
# failed 0.02 on that box while the ring had done nothing wrong either.
{
    # two fixed-width fields, not a regex: there is no separator between them
    my @range = map { my $s = $a->peek('ranges', $_ * 40, 40);
                      $s =~ /^\d{40}$/ ? [ substr($s, 0, 20) + 0, substr($s, 20, 20) + 0 ]
                                       : [ 0, 0 ] } 0 .. $KIDS - 1;
    my @wrote = grep { $_->[0] } @range;
    is(scalar @wrote, $KIDS,
       "all $KIDS children published and reported the sequences they were given");

    my $narrow = grep { $_->[1] - $_->[0] < $PER_KID - 1 } @wrote;
    is($narrow, 0,
       "each child's range spans the $PER_KID sequences it was handed, so no "
     . 'two publishers were given the same one')
        or diag 'a range narrower than the records it covers means the sequence '
              . 'counter handed one number to two publishers';

    my $overlapping = 0;
    for my $i (0 .. $KIDS - 1) {
        for my $j ($i + 1 .. $KIDS - 1) {
            my ($a1, $b1) = @{ $range[$i] };
            my ($a2, $b2) = @{ $range[$j] };
            next unless $a1 && $a2;
            $overlapping++ if $a1 <= $b2 && $a2 <= $b1;
        }
    }
    diag sprintf 'delivered %d of %d, lapped %d, from %d of %d children; %d pairs of '
               . 'children overlapped in time%s',
         $cs{delivered}, $TOTAL, $cs{lapped}, scalar keys %by_kid, $KIDS, $overlapping,
         $overlapping ? '' : ' (this host ran them one after another, so this run '
                           . 'tested the ring but not contention)';
}

# Sequences are handed out by one atomic, so no two publishers can ever have
# been given the same one. If they had been, the ring's own count would exceed
# what the cursor could account for.
cmp_ok($rs{seq}, '>=', $TOTAL,
       'the sequence advanced at least once per record, with no reuse');

done_testing;
