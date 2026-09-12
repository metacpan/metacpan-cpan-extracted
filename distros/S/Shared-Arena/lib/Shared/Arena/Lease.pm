package Shared::Arena::Lease;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Lease - one holder at a time, and a successor when it dies

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(name => 'app', size => 1 * 1024 * 1024);
    my $lease = $arena->lease('cron', ttl => 30);

    # in every worker's loop
    if ($lease->acquire) {
        run_due_jobs();       # only one worker reaches this
        $lease->renew;        # and it keeps the lease by saying so
    }

=head1 DESCRIPTION

A pre-forked pool eventually needs exactly B<one> worker to do something: run
the cron, warm a cache, apply a migration, own a scheduler. "The first worker"
is not an answer, because the first worker restarts. A lease is the answer:
whoever holds it is the one, and when the holder stops renewing it - because it
exited, crashed, or wedged - a successor takes it over.

This is the arena's peer table (the thing that lets a reader prove a publisher
died) turned into a feature you can name and hold.

Get one from C<< $arena->lease($name) >>. Every process asks for the same name;
the first creates the lock and the rest attach to it.

=head2 The deadline is what matters; the pid check only makes it faster

A holder must renew before its C<ttl> runs out. One that cannot - it is wedged,
stopped, or off the CPU too long - loses the lease when it lapses, whether or
not it is technically still running. That is the right answer: a leader that
cannot renew is not leading, and a successor should take over.

The lease also notices when a holder is B<provably dead> - the process is gone -
and lets a successor take over at once rather than waiting out the full
deadline. This only ever makes a handover happen sooner, never against a live
holder that is still renewing. A recycled pid that happens to be alive again
just means the successor waits out the deadline instead, which is slower, not
wrong.

=head2 The fencing token

C<acquire> hands back a generation, and so does L</fence>. The classic
distributed-lock hazard is a holder that was paused, lost the lease to a
successor, then woke up and acted as though it still held it. Two defences:

C<renew> checks the generation, so a holder that comes back after losing the
lease is told so rather than carrying on.

And for the write it was about to make, stamp it with the fence: a resource that
records "the highest fence I have accepted" can reject a write carrying an older
one, so a superseded leader's late write is refused by the thing it was writing
to. This is the only fully safe fix for the paused-leader problem, because no
lease can promise a process will notice it was paused before it acts.

    my $fence = $lease->fence;
    $db->write($row, $value, fence => $fence);   # db rejects a stale fence

=head2 Losing the lease safely

Every operation is done under a lock in the arena. If that lock cannot be taken
- which happens only when a process died holding it - the lease B<biases safe>:
C<acquire> returns false and C<renew> returns false, so the worst a wedged lock
can do is make leadership briefly unavailable, never doubly held. The deadline
then recovers it.

=head1 METHODS

=head2 acquire

    my $held          = $lease->acquire;
    my ($held, $took) = $lease->acquire;
    my $held          = $lease->acquire(ttl => 10);   # override this take

Take the lease, or extend it if we already hold it. True when this process holds
it afterwards, false when another process holds a current one.

In list context the second value is true when this acquire B<took over> a holder
that had lapsed or died, rather than starting from a free lease - so a caller
that must run recovery on becoming leader (re-read state, re-arm timers) can tell
a takeover from a clean start.

The process holds the lease, not the handle: two handles to the same name in one
process both see themselves as the holder, because the holder is the pid.

=head2 renew

    $lease->renew or step_down();
    $lease->renew(ttl => 10);

Extend a lease we hold. True while we still hold it at the generation we acquired
at; false once a successor has taken it. B<A holder that returns from a long
pause must check this>, not assume it still leads.

=head2 release

    $lease->release;

Give the lease up now, so a successor takes it immediately rather than after the
deadline. True when we held it and released it. A handle going out of scope is
B<not> a release - the lease lives in the arena and the process keeps holding it
until it lapses or calls this.

=head2 mine

    if ($lease->mine) { ... }

True when this process holds the lease right now, at the generation it acquired,
and it has not lapsed. Cheap and lock-free - the check to make inside a loop
before doing leader work.

=head2 holder

    my $pid = $lease->holder;

The pid that effectively holds the lease now, or 0 when it is free or lapsed. A
lapsed holder reports 0, not its stale pid: a successor could take the lease this
instant, so the old pid is not something to act on.

=head2 fence

    my $token = $lease->fence;

The generation this handle acquired at - the fencing token. See L</The fencing
token>.

=head2 stats

    my %s = $lease->stats;
    # name, held, holder, fence, acquires, steals

C<acquires> is every time the lease changed hands, including the first take;
C<steals> is the subset that took it from a lapsed or dead holder. A C<steals>
count climbing in steady state means holders keep dying or failing to renew in
time - either a real fault, or a C<ttl> too short for how often the holder
actually calls C<renew>.

=head1 CAVEATS

A lease is a coordination primitive on one machine, not a distributed consensus
protocol. It does exactly what a deadline plus a liveness check can do, which is
enough for "one worker in this pool owns this job" and not enough for anything
that needs agreement across machines.

The safe fix for a paused holder acting late is the fencing token, not the
lease alone. A lease can tell a holder it has lost - if the holder asks. It
cannot stop a holder that never asks, which is why L</fence> exists.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Ring::Group>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
