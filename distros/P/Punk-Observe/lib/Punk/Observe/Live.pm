package Punk::Observe::Live;

use 5.010;
use strict;
use warnings;

use Punk::Observe ();

our $VERSION = $Punk::Observe::VERSION;

1;

__END__

=head1 NAME

Punk::Observe::Live - the log tail, and what it admits losing

=head1 SYNOPSIS

    use Punk::Observe::Live;

    my $topic = Punk::Observe::Live::topic('acme');   # po.tail.acme

    my $rec = Punk::Observe::Live::roundtrip({
        t => '1774224000000000000', stream => '7', severity => 17,
        service => 'api', body => $line,
    });
    warn "line was cut\n" if $rec->{truncated};

=head1 DESCRIPTION

A browser tailing logs is connected to one worker. The lines it wants are
being ingested by all of them, so an ingesting worker publishes matching
records on a per-tenant topic and whichever worker holds the connection
forwards them.

Across a pool that is Hyperman's shared-memory bus, and it is optional: the
self-hosted default is one worker, where a tail never leaves the process it
was ingested in. L</have_bus> reports which this build got.

=head2 The transport refuses oversize; this does not

The bus returns an error for a message larger than its slot rather than
shortening one. Publishing a long log line unchanged therefore produces no
line at all, and the tail would silently skip exactly the interesting ones.

So the record is cut here, deliberately, and B<the flag travels with it>. A
truncation the reader can see is a different thing from a line that never
arrived.

=head2 Everything lost carries a number

A lapped consumer, a reconnection whose last event id has scrolled out of the
buffer, and a client that stopped reading are each reported with a count. A
silently short stream is indistinguishable from a quiet one.

=head1 FUNCTIONS

=head2 have_bus

    my $bool = Punk::Observe::Live::have_bus();

Whether this process has a Shared::Arena ring and can carry a tail across workers.
False means an in-process tail, which is correct for one worker and wrong for
a pool.

=head2 slot_sizes

    my ($ours, $bus) = Punk::Observe::Live::slot_sizes();

The slot size records are encoded against, and the bus's own - zero where
there is no bus. They must agree: a record sized against the wrong constant
is refused rather than truncated, which is the failure this whole module
exists to avoid.

=head2 topic

    my $topic = Punk::Observe::Live::topic($tenant);

The publish topic for a tenant, or C<undef> where the tenant id is not
C<[A-Za-z0-9_-]{1,64}>. The tenant is part of the topic because a tail is a
query and carries one; a topic accepting arbitrary bytes is a way to
subscribe to another tenant's stream.

=head2 roundtrip

    my $r = Punk::Observe::Live::roundtrip(\%rec);

Encodes a record for a slot and decodes it straight back. Takes C<t>,
C<stream>, C<severity>, C<service> and C<body>; returns those fields as they
survived, plus:

    encoded_len  bytes on the wire
    fits_slot    true when the transport will accept it
    truncated    true when anything was cut
    flagged      true when the DECODED record says so

C<truncated> and C<flagged> are separate on purpose: the first is what the
encoder did, the second is what a reader on the far side can see. They must
agree.

=head2 decode_bad

    my $ok = Punk::Observe::Live::decode_bad($bytes);

Runs the decoder over arbitrary bytes and reports whether it accepted them. A
slot is untrusted input the moment another process wrote it, and a length
field claiming more than the slot holds must be refused rather than followed.

=head2 ring

    my $r = Punk::Observe::Live::ring({ cap => 512, bytes => '524288',
                                        rows => \@rows, since => $last_id });

The resume buffer that backs C<Last-Event-ID>. Pushes every row, then reports
what follows C<since>:

    rows     [ { id => '7', data => '...' }, ... ]
    missed   how many were lost between `since` and the oldest held
    evicted  how many scrolled off the back in total
    held     how many are held now
    oldest   the oldest id still held
    bytes    what they occupy

C<missed> is the point. A reconnection that quietly restarts from the oldest
available row hides a gap; this one is told the size of it. C<since> of 0 is
a fresh connection, which missed nothing because it had seen nothing.

The buffer is bounded by rows B<and> by bytes, because the row bound alone
would let one connection hold a megabyte for a resume nobody may ever ask
for.

=head2 flow

    my $r = Punk::Observe::Live::flow($limit, \@sizes, $drain_each);

Backpressure. Admits rows until the unread total would exceed C<$limit>, then
closes. Returns C<admitted>, C<refused>, C<pending> and C<closed>.

A browser that has stopped reading must not become an unbounded queue in the
server, so the connection is closed with a reason rather than the worker
growing a buffer until something unrelated fails.

=head2 sse

    my $frame = Punk::Observe::Live::sse($id, $event, $data);

One SSE frame. The id is never omitted, because it is what makes a resume
possible at all, and a body containing a newline is split across C<data:>
lines - otherwise the frame ends early and the rest of the line becomes the
next event.

=head2 heartbeat

    my $frame = Punk::Observe::Live::heartbeat();

A bare comment frame, sent on an idle stream so an intermediary does not
close it. It carries no id: a heartbeat that advanced C<Last-Event-ID> would
make a reconnection resume past real rows.

=head2 bus_init

    my $ok = Punk::Observe::Live::bus_init($slots);

Brings up the shared bus arena. Called B<before> the fork: a subscription
made afterwards lands in one worker, and a cursor that starts at "now"
silently misses everything published before it.

=head2 bus_publish

    my $rc = Punk::Observe::Live::bus_publish($topic, $payload);

Publishes one record. A negative return is a refusal - oversize, or no bus in
this build.

=head2 bus_drain

    my $d = Punk::Observe::Live::bus_drain($topic);

Everything published on C<$topic> since the last call, as C<< { count, gaps,
rows } >>. Records on other topics are not returned; forwarding another
tenant's topic would be the tenancy boundary failing open.

C<gaps> counts what this consumer was lapped past. Reporting it is not
optional.

=head2 bus_reset_cursors

    Punk::Observe::Live::bus_reset_cursors();

What a post-fork hook calls. A cursor is a position in a stream this process
has not been reading, so an inherited one either replays what the parent
handled or skips what it has not - and both look like a broken tail rather
than a fork bug. The reset starts at the current sequence, never at zero.

=head1 SEE ALSO

L<Punk::Observe>, L<Punk::Observe::Log>, L<Punk::Observe::Query>

=cut
