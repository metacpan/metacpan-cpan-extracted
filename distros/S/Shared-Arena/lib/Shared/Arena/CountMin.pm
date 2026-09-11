package Shared::Arena::CountMin;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::CountMin - how often a key has been seen, in fixed space

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $cms   = $arena->countmin('requests', error => 0.001);

    # in every worker
    my $seen = $cms->add($ip);
    warn "$ip is loud" if $seen > 10_000;

    my $n = $cms->estimate($ip);      # without counting one

=head1 VERSION

Version 0.02

=head1 DESCRIPTION

L<Shared::Arena::Bloom> answers "have I seen this key". L<Shared::Arena::Histogram>
answers "what does the distribution look like". Neither answers B<how often have
I seen THIS key>, which is the question behind most abuse detection: which
client is hammering the gateway, which query is being repeated, which key
deserves a limit the others do not.

L<Shared::Arena::Map> would answer it exactly, and needs a slot per key. Key
cardinality is the one thing an abuse detector cannot bound, because the whole
problem is that somebody is generating keys, so the exact structure is the first
one to fall over.

A sketch stores no keys at all. It is a fixed grid of counters: every key is
hashed to one counter per row, an add increments all of them, and the estimate
is the smallest. Its size is chosen once and never changes, whether it is
counting ten keys or ten million.

Get one from C<< $arena->countmin($name) >>. Every process can ask for the same
name with the same arguments; the first creates it and the rest attach.

=head2 It answers high, and never low

That asymmetry is the contract, and it is the right way round. Two keys sharing
a counter make each look busier than it is; nothing can make either look
quieter. So a sketch B<never misses a heavy hitter> - it can only accuse a quiet
key of being loud, and how often it does that is what you chose when you sized
it.

=head2 The error is a fraction of the total

Sized with C<< error => 0.001 >> and C<< confidence => 0.99 >>, an estimate
exceeds the truth by more than C<error> times the B<total of everything added>
at most one time in a hundred.

Read that again, because it is the part that surprises people: the error is
relative to the whole stream, not to the key's own count. A sketch at one in a
thousand over a stream of ten million is accurate to ten thousand, which finds
the client making a million requests and says nothing whatever about the one
that made three.

C<stats> reports C<total> and the absolute C<error> that follows from it, so an
estimate never has to be quoted without its error bar:

    my %s = $cms->stats;
    my $n = $cms->estimate($key);
    printf "%s: between %d and %d\n", $key, $n - $s{error}, $n;

If you need small counts to be right, you need a L<Shared::Arena::Map>. A sketch
is for finding the loud, not for auditing the quiet.

=head2 What it will not do

B<It cannot list anything.> It holds no keys, so it can answer about a key you
name and can never tell you which keys exist. "The top ten" is a different
structure: a candidate set beside the sketch - a L<Shared::Arena::Map> of the
keys currently believed to be heavy - which a caller updates when C<add> returns
an estimate above the smallest one in it. The sketch supplies the counts; the
map supplies the names.

B<It cannot decrement.> Subtracting breaks the guarantee that the minimum is an
upper bound. A sketch is reset, or rotated between two, never decremented.

B<It does not do conservative update.> The well-known refinement - incrementing
only the counters that are at the current minimum - cuts the overestimate
substantially and is deliberately absent. It is a read-then-write, so two
processes doing it at once can each decide a counter needs no increment because
the other's is not yet visible, and the counter ends up short. A sketch that can
underestimate has lost the only thing it guarantees, and it fails silently,
because a low answer looks exactly like a quiet key. A plain increment cannot be
lost.

B<Reset is not atomic.> Clearing walks the grid, so a count running at the same
moment may see it half cleared and answer low for a key being forgotten. A
caller who cannot accept that rotates two sketches instead:

    my $now  = $arena->countmin('reqs-a', error => 0.001);
    my $then = $arena->countmin('reqs-b', error => 0.001);

    $now->add($key);
    my $n = $now->estimate($key) + $then->estimate($key);

    # at the turn of the window
    $then->reset;
    ($now, $then) = ($then, $now);

=head2 What a crash leaves behind

An add is one atomic increment per row with nothing to roll back, so a process
killed part way through has counted its key in some rows and not others. That
reads back as a slightly B<lower> estimate for that one key, and as nothing at
all for every other key. There is no repair step, no lock to release, and
nothing the next process has to know.

=head1 METHODS

=head2 add

    my $now = $cms->add($key);
    my $now = $cms->add($key, 50);

Counts one, or C<$n>, and returns what the sketch now believes the key's count
to be. The estimate costs nothing extra - the counters are already in hand - and
it is what a caller asking "has this key just crossed my threshold" wants.

=head2 estimate

    my $n = $cms->estimate($key);

What the sketch believes, without counting anything. At most C<error> times
C<total> too high, and never too low.

=head2 reset

    $cms->reset;

Forgets everything, including the total. Not atomic: see above.

=head2 stats

    my %s = $cms->stats;
    # rows, width, bytes, total, adds, error

C<error> is the absolute bound at the current total: an estimate may be that
much too high and no more, with the confidence the sketch was sized for.

=head2 rows, width

    my $d = $cms->rows;
    my $w = $cms->width;

The shape. C<width> is rounded up to a power of two from whatever the sizing
asked for, which only makes it more accurate.

=head1 SIZING

    $arena->countmin($name, error => 0.001, confidence => 0.99);

C<error> is epsilon and C<confidence> is one minus delta, and the grid follows:
C<width = e / error>, C<rows = ln(1 / (1 - confidence))>. Asking for C<rows> and
C<width> directly is available and is almost always a way of getting them wrong.

Counters are 64 bits, because a sketch counts a stream and a stream on a busy
gateway passes four billion in a day. A 32-bit counter would have to saturate to
avoid wrapping to nearly zero, which is the one answer this structure promises
never to give.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Bloom>, L<Shared::Arena::Map>,
L<Shared::Arena::Rate>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
