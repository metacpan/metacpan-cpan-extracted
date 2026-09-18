package Shared::Arena::HyperLogLog;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.09';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::HyperLogLog - how many distinct, in a few kilobytes

=head1 VERSION

Version 0.09

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(name => 'app', size => 1024 * 1024);
    my $hll   = $arena->hll('visitors', precision => 14);

    # in every worker, on every request
    $hll->add($client_ip);

    # anywhere, whenever
    printf "%.0f distinct visitors (about %.1f%% either way)\n",
        $hll->count, 100 * { $hll->stats }->{error};

=head1 DESCRIPTION

The bloom and cuckoo filters answer "have I seen this key?" and the count-min
sketch answers "how often?". This answers the third question, B<how many
different ones?>: distinct visitors today, distinct client addresses behind one
token, distinct URLs a crawler touched.

Neither obvious answer works. A map of every key seen is unbounded. Counting per
worker is wrong by construction: one visitor lands on eight workers and is
counted eight times, and adding the eight counts does not undo that.

A HyperLogLog sketch does it in fixed space. It keeps no keys, only a small table
of witnesses to how many different hashes it has seen, and from that estimates
the count to within a known relative error: about C<1.04 / sqrt(2^precision)>,
which at the default precision of 14 is 0.8% for 16 kilobytes, or 0.4% for 64.

=head2 The sketch every worker shares, with nothing to contend on

Adding a key raises one register to the larger of its old value and the new
one. A maximum does not care what order it is applied in, nor whether it is
applied twice, so eight processes adding to one sketch never need a lock, never
wait on each other, and cannot tear each other's writes. Of everything in this
distribution this is the tenant shared memory suits best: the operation is
already commutative, and the arena only has to let everybody reach it.

For the same reason two sketches B<merge> into the sketch of their union with
no coordination at all, register by register. Keep one sketch per minute and
merge sixty of them for the hour, or one per worker-group and merge for the
pool.

=head2 Precision

C<precision> is set when the sketch is created; a later caller names the same
one or leaves it out and inherits it. It is the one number to choose:

    precision   registers   bytes    error
        10         1024      1 KB    3.3%
        12         4096      4 KB    1.6%
        14        16384     16 KB    0.8%    (the default)
        16        65536     64 KB    0.4%
        18       262144    256 KB    0.2%

The error is a standard deviation, so about one estimate in three is further
off than that and about one in twenty is more than twice as far. It holds from
a handful of keys to billions; the estimator is unbiased across that whole range
rather than good in the middle and patched at the ends.

=head1 METHODS

=head2 add

    $hll->add($key);

Count a key. Adding the same key again changes nothing, which is the whole
point: a visitor seen a thousand times is one visitor. Lock-free.

Returns true if the sketch changed. That is a hint about the sketch, not an
answer about the key: a new key can leave the sketch unchanged because another
key had already raised the same register. Use a filter for "have I seen this?".

=head2 count

    my $n = $hll->count;

The estimate of how many distinct keys have been added, by every process that
added to this sketch. A floating-point number; round it yourself.

=head2 merge

    $hll->merge($other);

Fold another sketch of the same precision into this one, after which this one
estimates the union of everything either saw. The other sketch is not changed.
Croaks on a precision mismatch, which is a bug rather than a condition.

=head2 reset

    $hll->reset;

Forget everything. A key added at the same instant lands either before the
reset and is forgotten or after it and is kept.

=head2 precision, stats

    my $p = $hll->precision;
    my %s = $hll->stats;    # precision, registers, bytes, filled, error

C<filled> is how many registers are non-zero, which is how full the sketch
looks; C<error> is the standard relative error to quote beside any count.

=head1 CAVEATS

A sketch answers one question, "how many distinct?", and nothing else: not
which keys, not whether a given key is among them, not how often any of them
appeared. Those are the map, the filters and the count-min sketch.

Two sketches merge only at the same precision. Pick one precision for a family
of sketches you mean to merge and keep it.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Bloom>, L<Shared::Arena::Cuckoo>,
L<Shared::Arena::CountMin>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
