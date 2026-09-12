package Shared::Arena;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

use Frozen;

require XSLoader;
XSLoader::load('Shared::Arena', $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena - memory two processes can both read, without a syscall

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    use Shared::Arena;

    # in the parent, before the fork
    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $ring  = $arena->ring('events', slots => 4096, slot_size => 512);
    my $cursor = $ring->cursor;

    if (fork() == 0) {
        $ring->publish('hello', 'from the child');
        exit 0;
    }

    for my $rec ($cursor->drain) {
        my ($topic, $payload, $seq) = @$rec;
    }

    # or by name, from a process that is not a child at all
    my $arena = Shared::Arena->attach('my-app');

=head1 DESCRIPTION

Two processes on one machine that want to share a structure have, in Perl, a
pipe, a socket, a file or a database. Each costs a syscall and at least one
copy per message. The thing that removes both, a region of memory every process
maps and reads directly, is ordinary elsewhere and absent from CPAN.

C<Shared::Arena> is that region. It is mapped once, carved into named
sub-regions, and read by every process that maps it without any of them
copying, locking or calling into the kernel.

Eleven things come with it to put in one.

=over 4

=item * L<Shared::Arena::Ring> - a record queue that many processes write at
once and many read, each at its own pace.

=item * L<Shared::Arena::Map> - a fixed-capacity table with lock-free reads and
counters that increment in a single atomic instruction.

=item * L<Shared::Arena::Cache> - a map that evicts rather than refusing, so
one pool of workers warms one cache instead of N.

=item * L<Shared::Arena::Bloom> - a set that answers "no" exactly and "yes"
probably, and holds no keys at all.

=item * L<Shared::Arena::Cuckoo> - the same kind of set, which can also forget
a key, so members that expire are removed one at a time instead of the whole
set being rotated.

=item * L<Shared::Arena::CountMin> - counts how often each key has been seen
without storing any of them, which is how you find the loud one when you cannot
bound how many there are.

=item * L<Shared::Arena::Histogram> - a distribution every process adds to at
once, with no merge step and a bounded error.

=item * L<Shared::Arena::Rate> - a token bucket per key, so a limit enforced
across a pool is the limit you wrote rather than that limit times the number of
workers.

=item * L<Shared::Arena::Frozen> - one structure, published whole and read
where it lies: nested data every worker reads without any of them rebuilding
it.

=item * L<Shared::Arena::Lease> - one holder at a time, and a successor when it
dies: leader election for the one job in a pool that only one worker should do.

=item * L<Shared::Arena::Scoreboard> - one row per worker, published live: each
worker writes its own row with no lock, and a supervisor reads the whole board
in one pass, so a status page costs no pipe or socket per worker.

=back

The first eight store B<opaque bytes>, or in the case of the two filters and
the sketch no keys at all, so a nested structure has to be flattened going in
and rebuilt coming out. C<Shared::Arena::Frozen> is the one that does not
rebuild, and it is the reason L<Frozen> is a prerequisite.
C<Shared::Arena::Lease> and C<Shared::Arena::Scoreboard> store no caller data at
all: the lease holds a pid and a deadline, the scoreboard a row of gauges per
worker. They are coordination and observability rather than storage.

=head2 Two ways in

An B<anonymous> arena is mapped before a C<fork> and inherited. It has no name,
needs no cleanup, and disappears when the last process holding it exits.

A B<named> arena can be attached by any process that knows the name, related or
not. Creating a name that already exists attaches to it instead, so every
process can run the same setup code and exactly one of them will turn out to be
the creator. Ask C<created> which one that was.

=head2 Nothing inside an arena is a pointer

Every reference from one part of an arena to another is an offset. That is what
lets two processes map the same arena at two different addresses and read the
same structure, and it is the difference between something that can be attached
and something that can only be inherited.

=head2 Allocation is a bump, and there is no free

A sub-region is carved by advancing a high-water mark and lives as long as the
arena.

This is a limit on purpose. A free list that several processes share is
corrupted permanently by one of them dying between two writes, and the next
allocation then hands out memory somebody else is already using: a failure with
no symptom until it has a bad one. Nothing that wants an arena needs to release
a sub-region. A caller who genuinely needs reuse can do it inside its own
carved region, where getting it wrong costs one feature rather than everything.

=head2 Sizing one

C<size> is the usable bytes and the bookkeeping is added to it, so asking for
eight megabytes gives eight megabytes to spend. A ring costs
C<slots * slot_size> for its life. Everything is reserved when the arena is
created and nothing grows afterwards, so a carve that does not fit is refused
rather than served slowly.

=head1 METHODS

=head2 create

    my $arena = Shared::Arena->create(%opts);

=over 4

=item * C<size> - usable bytes, default one megabyte.

=item * C<name> - makes it a named arena other processes can attach to.

=item * C<regions> - how many sub-regions may be carved, default 64.

=back

Croaks if the arena cannot be created, saying what was wrong. Creating a name
that already exists attaches to it.

=head2 attach

    my $arena = Shared::Arena->attach($name);

Attaches to an existing named arena, or returns C<undef>. It never creates one:
attaching to a name nobody has used is a question with an answer, not an
instruction.

=head2 region

    my ($off, $len) = $arena->region($name, size => $bytes);
    my ($off, $len) = $arena->region($name);          # find, do not carve

Carves a named sub-region, or returns the one already carved under that name so
every process can ask for it the same way. An empty list if it does not exist,
the arena is full, or the name is unusable: names are one to thirty-one bytes.

=head2 poke, peek

    $arena->poke($name, $offset, $bytes);
    my $bytes = $arena->peek($name, $offset, $length);

Raw bytes in and out of a carved region, for a caller with a structure of its
own design. Croaks if the access would run past the region's end.

These do no locking of any kind. Two processes writing the same bytes get what
they deserve; use a ring, or coordinate.

=head2 ring

    my $ring = $arena->ring($name, slots => 4096, slot_size => 512);

A L<Shared::Arena::Ring> in this arena, created on first use. Every process may
call this with the same arguments.

=head2 map

    my $map = $arena->map($name, slots => 4096, slot_size => 512);

A L<Shared::Arena::Map> in this arena, created on first use. Every process may
call this with the same arguments.

=head2 bloom

    my $b = $arena->bloom($name, capacity => 1_000_000, fp_rate => 0.001);

A L<Shared::Arena::Bloom> in this arena, created on first use. Every process may
call this with the same arguments.

=head2 cuckoo

    my $f = $arena->cuckoo($name, capacity => 1_000_000);

A L<Shared::Arena::Cuckoo> in this arena, created on first use. Every process
may call this with the same arguments.

A set like the bloom filter's that can also C<remove> a key. Its false-positive
rate is fixed, at about 0.011% when it holds its capacity, and when it is full
it refuses the next key instead of saturating.

=head2 histogram

    my $h = $arena->histogram($name, max => 60_000_000, sigbits => 5);

A L<Shared::Arena::Histogram> in this arena, created on first use. Every process
may call this with the same arguments.

=head2 cache

    my $c = $arena->cache($name, capacity => 4096, entry_size => 4096);

A L<Shared::Arena::Cache> in this arena, created on first use. Every process may
call this with the same arguments.

=head2 frozen

    my $conf = $arena->frozen($name, size => 256 * 1024, slots => 4);

A L<Shared::Arena::Frozen> in this arena, created on first use. Every process
may call this with the same arguments.

C<size> is the largest block it will carry and the region costs C<size * slots>,
because a publish never writes where a reader is reading.

=head2 lease

    my $lease = $arena->lease($name, ttl => 30);

A L<Shared::Arena::Lease> in this arena, created on first use. Every process may
call this with the same arguments.

Leader election: whoever holds the lease is the one worker that runs the cron,
warms the cache, applies the migration. When the holder stops renewing - it
exited, crashed, or wedged - a successor takes it over. C<ttl> (seconds) is how
long an acquire or renew keeps it before it lapses; the holder must renew inside
that window.

    if ($lease->acquire) {
        # I am the one, for now
        run_the_scheduled_job();
        $lease->renew;      # ... and keep saying so
    }

Unlike every other tenant here, C<$name> is not a store of the caller's bytes -
it names a single lock. See L<Shared::Arena::Lease> for the deadline, the
fast handover when a holder is provably dead, and the fencing token.

=head2 scoreboard

    my $sb = $arena->scoreboard($name,
                                fields => ['inflight', 'served'],
                                slots  => 256);

A L<Shared::Arena::Scoreboard> in this arena, created on first use. C<fields>
names the gauge columns, set once by whoever creates the board; a later caller
names the same ones or inherits them, and inherits C<slots> too, so a worker
need not know how big the supervisor made it.

One row per worker, published live. Each worker claims a row and is its only
writer, so an update takes no lock; a supervisor reads every row in one pass.

    # in each worker, after the fork
    $sb->take;
    $sb->update(inflight => $n, served => $total, status => "GET $path");

    # in the supervisor or a status endpoint
    for my $row ($sb->all) {
        printf "pid %d %s %s\n", $row->{pid},
               ($row->{alive} ? 'up' : 'DEAD'), $row->{status};
    }

It is the inverse of the other tables: instead of many writers contending on
one structure, each worker owns its own row and nobody contends at all. A dead
worker's row is shown as not alive and reclaimed by the next worker to start.

=head2 rate

    my $rl = $arena->rate($name, limit => 100, window => 60, slots => 4096);

A L<Shared::Arena::Rate> in this arena, created on first use. Every process may
call this with the same arguments.

C<limit> is the burst: the most one key may spend at once, and also how much a
full refill puts back. C<window> is how long that refill takes, in seconds, so
the two together are the sustained rate. C<slots> is how many distinct keys the
table holds; it is rounded up to a power of two.

A limiter is per policy rather than per call, so two routes with different
limits are two carves. That is deliberate: a table whose limit is whatever the
last caller passed is a table two callers can disagree about.

    $rl->allow($ip)          or return $c->status(429);
    $rl->allow($ip, 10)      or ...;   # an expensive route costs more

    $c->header('X-RateLimit-Remaining' => int $rl->remaining($ip));
    $c->header('Retry-After'           => int $rl->retry_after($ip) + 1);

B<A limit enforced per worker is not the limit you wrote.> Four workers each
keeping their own counter turn 100/min into 400/min, and the number changes
when the pool is resized. This keeps one bucket per key in memory every worker
already shares, so the limit is the limit whatever the pool does.

B<It is a token bucket, not a fixed window,> because a fixed window has a hole
at the boundary: a caller may spend its whole allowance at 11:59:59 and its
whole allowance again at 12:00:00, which is twice the limit in one second. A
bucket refills continuously and has no boundary to stand on.

=head2 countmin

    my $cms = $arena->countmin($name, error => 0.001, confidence => 0.99);

A L<Shared::Arena::CountMin> in this arena, created on first use. Every process
may call this with the same arguments.

How often a key has been seen, in space that does not grow with the number of
keys. It answers B<high and never low>, so a heavy hitter can never hide, and
the error is a fraction of the B<total> rather than of the key's own count: it
finds the client making a million requests and says nothing useful about one
that made three.

    my $seen = $cms->add($ip);
    warn "$ip is loud" if $seen > 10_000;

=head2 refused

    my $n = $arena->refused;

Registry entries this process has refused because the bytes they describe are
not inside the mapping.

B<It is zero, or something is wrong.> A non-zero count means the arena has been
written by something that should not have written it: a corrupt segment, or
another process on the machine. The entry is skipped rather than followed, so
the arena keeps working, but the number is how you find out at all.

=head2 regions

    my @names = $arena->regions;

=head2 size, created

    my $bytes   = $arena->size;
    my $is_mine = $arena->created;

=head2 base

    my $address = $arena->base;

Where this process mapped the arena. Of no use except to prove that two
mappings of one arena are at different addresses, which is what a test wants.

=head2 destroy

    Shared::Arena->destroy($name);

Removes a named arena's name. Existing mappings stay valid until their last user
exits, which is a feature and a leak at once and cannot be one without the
other: a creator that crashes leaves the arena behind, so a restarting server
reattaches to a live one and its readers never noticed, but nothing removes a
name nobody will open again. Call it when the arena's life is over.

=head2 have_atomics

    Shared::Arena::have_atomics() or fall_back();

Whether this build has the atomic operations everything here rests on. When it
does not, C<create> refuses rather than pretending, and a caller is expected to
degrade. See L</ATOMICS>.

=head1 WAKING A READER

Draining a ring never blocks, so a reader either polls or waits to be told. To
wait to be told, ask for wakeups B<before the fork>:

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    $arena->wakers(16);                 # before any fork

    # in each process that will read
    $arena->waker;
    my $fd = $arena->waker_fd;

    # and in its event loop
    vec(my $bits, $fd, 1) = 1;
    while (select(my $r = $bits, undef, undef, undef) > 0) {
        $arena->drained;                # before draining the ring
        my @recs = $cursor->drain;
    }

A wakeup means there is something to read: the notification follows the record,
never precedes it. Many records in quick succession cost one wakeup rather than
one each.

B<Only processes that inherited the arena can be woken.> The mechanism is a
pipe created before the fork, and a process that attached to a named arena
inherited nothing. There, C<waker_fd> returns -1 and the reader polls.

=head2 wakers

    $arena->wakers($count);

Creates the wakeup channels. Must run before the fork.

=head2 waker

    my $index = $arena->waker;

Claims one for this process, after the fork. Returns its index, or -1 when
there are none left, in which case the caller polls.

=head2 waker_fd

    my $fd = $arena->waker_fd;

The descriptor to select on, or -1 when this process has no wakeup channel.

=head2 drained

    $arena->drained;

Call after a wakeup and before draining the ring.

=head1 WHEN A PROCESS DIES

A publisher that is killed part-way through writing a record leaves a hole.
Every reader that reaches it faces a question with two wrong answers: skipping
a record that is merely late throws away live data, and waiting for one that
will never arrive stalls the reader for ever. A timeout picks one of those and
is wrong the rest of the time, because a live publisher on a loaded machine can
lose the CPU for longer than any bound worth setting.

So a reader does not wait on a clock. It asks whether the process that claimed
the record still exists, and requires two independent answers to agree: that the
process is gone, and that it has made no progress at all for a grace period.
Both must hold. A process that is alive but wedged fails the second; a process
whose identifier has been reused passes the first, and the disagreement costs
one stalled record rather than a lost one.

Once a hole is proven abandoned it is B<filled>, not skipped, so every other
reader passes it by reading rather than by waiting. The record is counted as
C<abandoned> and never as C<lapped>, because a crash and a slow reader are
different diagnoses.

=head2 peers

    my %p = $arena->peers;   # used, live, reaped

Processes registered with this arena. C<reaped> is how many were found dead
holding an unfinished record.

=head1 ATOMICS

Everything here rests on atomic loads, stores and compare-and-swap. Where the
compiler provides none, C<create> refuses instead of pretending, and
C<have_atomics> reports which build this is. That is a supported configuration
rather than a broken one: a caller is expected to fall back to whatever it did
before.

=head1 THE HOT METHODS ARE OPCODES

The doors called in a loop are compiled to run without a subroutine call:
C<get> and C<set> on a cache, C<fetch>, C<store>, C<exists>, C<incr> and
C<counter> on a map, C<add> and C<check> on either filter, C<add> and
C<estimate> on a sketch, C<record> on a histogram, C<publish> on a ring, and
C<allow>, C<remaining> and C<retry_after> on a limiter. The optional arguments
are compiled too: C<set> with a C<ttl>, C<incr> with a step, C<record> and a
sketch's C<add> with a count, C<allow> with a cost.

Nothing needs doing to get this. The ordinary method call B<is> the fast path,
there is no second API to migrate to, and the answers are identical either way,
including which of them return an empty list for a miss.

Measured on an M-series Mac, nanoseconds per call, ordinary against compiled:

    cache->get     60.2  ->  42.4
    cache->set     37.4  ->  30.2
    map->fetch     54.1  ->  42.6
    map->exists    30.9  ->  23.8
    map->incr      37.6  ->  24.4
    bloom->check   31.9  ->  22.8
    bloom->add     30.6  ->  21.1
    cuckoo->check  29.8  ->  23.5
    countmin->add  30.2  ->  24.9
    hist->record   25.1  ->  13.1

and for the optional arguments and the rest of a limiter:

    map->incr($k, $by)          40.4  ->  20.9
    cache->set(..., ttl => N)   42.8  ->  29.9
    hist->record($v, $n)        30.3  ->  16.1
    countmin->add($k, $n)       33.4  ->  22.3
    rate->allow($k, $cost)      37.5  ->  27.1
    rate->remaining             34.0  ->  21.8
    rate->retry_after           34.0  ->  22.8
    map->counter                38.5  ->  21.7

Anything that would change the answer takes the ordinary path instead: a
subclass that overrides the method, a replaced subroutine, an argument list of
a width the call site was not compiled with, an object whose handle has been
released. So a debugger, a profiler and C<local *Some::Method = sub {...}> all
work the way they did.

C<cache-E<gt>get> has a twist worth knowing: L<Frozen> compiles its own
C<-E<gt>get> the same way, and two of these cannot own one call site. Frozen
gets there first, so at a C<get> call site this module answers from the half
that is left and skips the other entirely, rather than falling back to an
ordinary call. Both remain correct and neither is slowed by the other.

=head2 What it costs a program that does not use it

The compiler hook sees every call site in the process with one of those names,
not only this module's. A call on some other class runs a guard, is declined,
and takes its ordinary path: B<2.5ns> per call, measured at 39.6 against 42.1.

If a program makes millions of those and few of these, set

    SHARED_ARENA_NO_XOP=1

in the environment before it starts. Every door then goes through the ordinary
subroutine, and nothing else changes. It is read once, when the module loads,
because the rewriting happens at compile time.

=head1 CAVEATS

B<One machine.> An arena is memory, not a protocol. Nothing here crosses a
network, and nothing is written to disk.

B<Not durable.> A record lives until the ring wraps or the last process exits.
Anything that must survive a machine restart belongs in a database.

B<No security boundary.> Every process that can map the arena can read and write
all of it. A named arena is created with owner-only permissions, and that is the
whole of the protection.

B<Trusted contents.> The arena is written by programs you run, not by strangers.
A process that can write to the mapping can make another one read nonsense, and
nothing here can stop it: there is no signature on a record and no way to tell a
value you wrote from a value somebody else did.

What it will B<not> do is follow such a value out of the mapping. Structural
checks refuse an arena this build cannot read; a registry entry whose extent is
not inside the mapping is skipped and counted in L</refused>; and a tenant
checks the shape stored in its own header against that entry's length before it
reads a byte of it. Corrupt contents are wrong answers, not out-of-bounds
access.

That distinction is the whole of the protection and it was not always true: a
process that knew only the arena's name could rewrite one registry entry and
make the next process to bind that tenant write twenty-one kilobytes past the
end of its own mapping. t/30-bounds.t is that attack, and it is a test rather
than a note because the promise is worth nothing if nobody checks it.

B<Threads get no copy.> Every object here stands for memory this process
mapped, so a new ithread is given an inert copy of each one rather than a second
owner of the same mapping, and the first of the two to go cannot unmap it under
the other. A thread that wants the arena attaches to it by name, as another
process would. Windows emulates C<fork> with threads, so the same holds for a
forked child there. A L<Shared::Arena::Lease> is held per process, and two
threads are one process.

=head1 SEE ALSO

L<Shared::Arena::Frozen>, L<Shared::Arena::Frozen::View>, L<Frozen>,
L<Shared::Arena::Ring>, L<Shared::Arena::Ring::Cursor>, L<Shared::Arena::Map>,
L<Shared::Arena::Bloom>, L<Shared::Arena::Histogram>, L<Shared::Arena::Cache>,
L<Shared::Arena::Rate>, L<Shared::Arena::CountMin>, L<Shared::Arena::Cuckoo>,
L<Shared::Arena::Ring::Group>, L<Shared::Arena::Lease>,
L<Shared::Arena::Scoreboard>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-shared-arena at
rt.cpan.org>, or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Shared-Arena>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
