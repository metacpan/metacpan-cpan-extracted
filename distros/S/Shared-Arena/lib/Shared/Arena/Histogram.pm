package Shared::Arena::Histogram;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.03';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Histogram - a distribution every process adds to at once

=head1 VERSION

Version 0.03

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $h = $arena->histogram('latency', max => 60_000_000, sigbits => 5);

    # in any worker, on every request
    $h->record($elapsed_us);

    # anywhere, at any time
    printf "p50 %d  p99 %d  of %d\n",
        $h->quantile(0.5), $h->quantile(0.99), $h->count;

=head1 DESCRIPTION

Recording a value is one atomic add to one bucket. There is no merge step and
no per-process copy, so a percentile across a whole pool of workers is the same
question as a percentile across one of them, and costs the same to ask.

Get one from C<< $arena->histogram($name) >>. Every process can ask for the same
name with the same arguments; the first creates it and the rest attach.

=head2 Why buckets rather than the values

A distribution is wanted continuously and the values are not. Keeping them means
memory proportional to traffic and a sort to answer anything. Bucketing means
fixed memory and an answer that is already computed.

What that costs is exactness, and the point of the scheme below is that the
inexactness is B<bounded and known> rather than being whatever the buckets
happened to be.

=head2 The bound, and why it is the same everywhere

Each power of two is divided into C<2 ** sigbits> equal sub-buckets. The
relative error of any value is therefore at most C<1 / 2 ** sigbits>, and it is
the same at a microsecond as at an hour. C<error> reports it.

    sigbits   error    good for
       3      12.5%    rough shape
       4       6.2%    the default
       5       3.1%    latency you report to somebody
       7       0.8%    latency you promise somebody

Bucket count grows with the logarithm of the range, so tightening the bound
costs surprisingly little: covering one to a billion at 3% is a few hundred
buckets. Values below C<2 ** sigbits> are recorded B<exactly>, because at that
size a bucket is one unit wide.

=head2 What a quantile means here

A quantile is reported as the B<top> of the bucket it falls in, so it is never
optimistic: it will not claim the service was faster than it was. For a latency
budget that is the useful direction to be wrong in.

It is also walked while values are still arriving, and no attempt is made to
stop that. Stopping every process to read a distribution would cost more than
the answer is worth, and the answer describes a moving thing in any case.
C<count> and C<sum> are read the same way, so a mean computed from them can
disagree with the buckets by whatever arrived in between.

C<min>, C<max> and C<sum> are B<exact>: they are comparisons and additions, not
buckets.

=head2 Values past the ceiling

A value above C<max> is counted in C<over> and is B<not> clamped into the top
bucket. Clamping would let a flood of enormous values look like a busy top
bucket, and every quantile would read plausibly while being wrong. Counted
apart, an overflow is visible for what it is: a sign the ceiling was set too
low.

=head1 METHODS

=head2 record

    $h->record($value);
    $h->record($value, $times);

=head2 quantile

    my $p99 = $h->quantile(0.99);

The top of the bucket the quantile falls in. C<0> when nothing has been
recorded.

=head2 count

    my $n = $h->count;

=head2 stats

    my %s = $h->stats;
    # count, sum, min, max, mean, over, buckets, sigbits

=head2 buckets

    for my $b ($h->buckets) {
        my ($low, $high, $count) = @$b;
    }

The non-empty buckets, for drawing the shape rather than asking for a number.

=head2 error

    my $bound = $h->error;

The largest fraction by which a recorded value and what this reports back can
differ. A runtime answer, because it follows from C<sigbits>.

=head2 reset

    $h->reset;

Forgets everything. Readers are not locked out, so a quantile taken at the same
moment may describe a half-cleared histogram.

=head1 SIZING ONE

    my $h = $arena->histogram('latency', max => 60_000_000, sigbits => 5);

C<max> is the largest value you expect to record, and anything above it is
counted as an overflow rather than recorded. C<sigbits> is between 1 and 8 and
buys precision at the cost of buckets; 4 is the default and 5 is a better
choice for anything anybody reads.

Pick a unit and stay in it. Microseconds for latency gives a useful floor and
still reaches an hour in about 400 buckets at 3% error.

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Map>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
