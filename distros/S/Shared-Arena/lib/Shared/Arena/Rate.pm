package Shared::Arena::Rate;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Rate - a token bucket per key, shared by every worker

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 4 * 1024 * 1024);
    my $rl    = $arena->rate('api', limit => 100, window => 60);

    # in every worker, after the fork
    unless ($rl->allow($ip)) {
        $c->header('Retry-After' => int $rl->retry_after($ip) + 1);
        return $c->status(429);
    }

    $c->header('X-RateLimit-Limit'     => 100);
    $c->header('X-RateLimit-Remaining' => int $rl->remaining($ip));

=head1 DESCRIPTION

A limit of 100 per minute enforced in a pre-forked pool is not a limit of 100
per minute. Each worker keeps its own counter, so the real limit is workers
times 100 per minute, and it changes when the pool is resized. The usual escape
is to put the counters in a file or a database, which buys the limit back at the
price of a syscall or a round trip on every request.

This keeps one bucket per key in memory every worker already shares. The limit
is the limit whatever the pool does, and checking it touches nothing but a
single word of memory.

Get one from C<< $arena->rate($name) >>. Every process can ask for the same name
with the same arguments; the first creates it and the rest attach.

=head2 A bucket, not a window

The obvious implementation is a counter and a window: count requests, reset the
count when the clock rolls over. It has a hole at the boundary. A caller limited
to 100 a minute can spend 100 at 11:59:59 and 100 more at 12:00:00, which is 200
requests in one second and is exactly what the limit was written to prevent. It
is also invisible in testing unless the clock happens to be in the right place
when you look.

A bucket has no boundary to stand on. It holds up to C<limit> tokens, refills
continuously at C<limit> per C<window>, and a request takes one. Two numbers a
caller actually wants fall out of that separately:

    limit => 100, window => 60     # 100/min, and up to 100 at once
    limit => 10,  window => 6      # still 100/min, but at most 10 at once

A window cannot express the difference.

=head2 What it costs, and what it cannot do

A bucket is B<one 64-bit word> - tokens in one half, the moment they were
counted in the other - so a check is a single compare-and-swap and takes no lock
at all.

That is also the whole crash story. A process that dies mid-check has either
landed its compare-and-swap or not; there is no half-written bucket to find and
nothing to repair. Unlike L<Shared::Arena::Ring>, this needs no peer table and
no proof that anybody died.

B<It is per key, and keys are not remembered for ever.> The table holds C<slots>
of them. A key whose bucket has refilled to full is indistinguishable from one
never seen, so its slot is reclaimable and the table drains itself with no sweep
and no timer. When every slot holds a bucket somebody is still spending from,
a new key takes over its home slot and resets one live bucket - which gives that
victim B<more> requests than it should have had, never fewer. A table that is
too small cannot turn into an outage. Watch C<evicted>.

B<It fails open, and says so.> With no atomics in the build there is no limiter
and C<allow> answers true. Under contention heavy enough to exhaust the
compare-and-swap retries it also answers true, and increments C<contended>. A
rate limiter that has quietly stopped limiting is a thing an operator has to be
able to see rather than infer from a suspiciously clean C<denied> count.

B<The clock wraps every 49.7 days.> Elapsed time is measured as a signed
difference, which is correct across that wrap for any interval up to half of
it. A key idle for longer than 24.9 days measures short and so refills slower
than it should, once, for one request.

Signed rather than unsigned because two processes read the clock at slightly
different moments, so a caller can find a timestamp in its key's slot that is
LATER than its own reading. Measured unsigned, that one millisecond is forty
nine days of refill, and the bucket comes back full.

=head2 One limiter is one policy

C<limit> and C<window> belong to the limiter, not to the call. Two routes with
different limits are two carves:

    my $login = $arena->rate('login', limit => 5,    window => 300);
    my $api   = $arena->rate('api',   limit => 1000, window => 60);

which costs a few kilobytes each. Asking for a name that already exists with
different numbers is refused rather than silently answered with somebody else's
policy, for the same reason every other tenant here checks its shape.

For charging one route more than another out of B<one> budget, pass a cost:

    $rl->allow($ip, 10) or return $c->status(429);

=head1 METHODS

=head2 allow

    if ($rl->allow($key))     { ... }
    if ($rl->allow($key, 10)) { ... }

Takes one token, or C<$cost> of them, and returns true when the request is
within the limit. This is the only method that spends anything.

It returns a plain boolean rather than a list, so C<< if ($rl->allow($ip)) >>
cannot be read as anything else. The numbers for a header come from
L</remaining> and L</retry_after>.

=head2 remaining

    my $left = $rl->remaining($key);

What the key could spend right now, in requests, as a fractional number. Spends
nothing.

=head2 retry_after

    my $secs = $rl->retry_after($key);

How long until one more request would be allowed, in seconds, as a fractional
number. Zero when one already is. This is what a C<Retry-After> header wants,
rounded up.

=head2 reset

    $rl->reset($key);

Refills one key to full: an operator lifting a limit by hand, or a test that
does not want to wait for a window.

=head2 forget

    $rl->forget($key);

Gives the key's slot back so another key can have it. Not required - a full
bucket is reclaimed on demand - but useful when a key is known to be finished
with, such as a session that has ended.

=head2 stats

    my %s = $rl->stats;
    # limit, window, slots, keys, allowed, denied, evicted, contended

C<evicted> counts live buckets taken over because the table had no room, and is
how you find out C<slots> is too small. C<contended> counts checks that gave up
and were allowed without being counted against anybody.

Counting C<keys> walks the whole table, so this belongs on a status page rather
than in a loop.

=head2 slots

    my $n = $rl->slots;

How many keys the table holds, rounded up to a power of two from what was asked
for.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Map>, L<Shared::Arena::Cache>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
