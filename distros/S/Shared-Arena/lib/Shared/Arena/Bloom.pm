package Shared::Arena::Bloom;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require Shared::Arena;

1;

__END__

=encoding utf8

=head1 NAME

Shared::Arena::Bloom - a shared set that answers "no" exactly and "yes" probably

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    my $arena = Shared::Arena->create(size => 8 * 1024 * 1024);
    my $seen  = $arena->bloom('seen', capacity => 1_000_000, fp_rate => 0.001);

    # skip work already done, in any process
    next if $seen->add($id);

    # or ask without adding
    do_expensive($id) unless $seen->check($id);

=head1 DESCRIPTION

A bit array and a handful of hash functions. Adding a key sets some bits;
asking about a key tests them. If any bit is clear the key was B<definitely>
never added. If all are set it B<probably> was, and the probability is a number
you chose when you sized the filter.

It holds no keys, so it costs the same for a million short ones as for a million
long ones, and a filter for a million items at one in a thousand is under two
megabytes. That is what makes it worth sharing: every process asks the same
question of the same bits without copying anything or taking a lock.

Get one from C<< $arena->bloom($name) >>. Every process can ask for the same
name with the same arguments; the first creates it and the rest attach.

=head2 What it will not do

B<It cannot forget one key.> Clearing a bit would clear it for every other key
that happens to share it, turning a definite "no" into a wrong one. There is no
delete, and there never will be. A filter only fills; when it is too full it is
replaced.

B<It cannot count.> C<estimated> in the stats is arithmetic on how many bits are
set, and it degrades as the filter saturates.

B<It cannot make a decision exactly once.> C<add> reports whether every bit was
already set, which is nearly always the answer you want, but the bits are set
one at a time: two processes adding the same key at the same instant can both be
told it was new. For deduplicating work that is harmless, because the loser
merely repeats something. For anything that must happen once, use a lock.

=head2 Sizing, and what happens past it

Ask for what you expect to hold and the rate you will accept:

    my $b = $arena->bloom('seen', capacity => 1_000_000, fp_rate => 0.001);

The bits and the number of hashes follow from those two numbers, and asking for
them directly is almost always a way of getting them wrong.

The rate you asked for is what you get B<at that capacity>. Past it the rate
climbs, and it climbs fast: a filter at twice its rating is not slightly worse,
it is several times worse. Watch C<fill> in the stats. At the rated capacity it
sits near one half, and a filter approaching saturation is answering "probably"
to almost everything, which is the same as answering nothing at all.

=head2 Rotating one

Because there is no delete, a long-running filter needs replacing rather than
tidying. The usual arrangement is two filters and a switch:

    my $current  = $arena->bloom('seen-a', capacity => 1_000_000);
    my $previous = $arena->bloom('seen-b', capacity => 1_000_000);

    # ask both, add to the current one only
    my $known = $current->check($id) || $previous->check($id);
    $current->add($id) unless $known;

    # when the current one fills, reset the older and swap the two
    if (($current->stats){fill} > 0.5) {
        $previous->reset;
        ($current, $previous) = ($previous, $current);
    }

which keeps a full window of history at all times and never asks a saturated
filter anything. Two filters are provided rather than one that rotates itself,
because how much history to keep is a decision only the caller can make.

=head1 METHODS

=head2 add

    my $already = $b->add($key);

Adds a key. Returns true when every bit was already set, meaning the key had
probably been added before, and false when this call set at least one.

=head2 check

    if ($b->check($key)) { ... }

False is exact: this key was never added. True is probable.

=head2 reset

    $b->reset;

Forgets everything. Readers are not locked out, so a check running at the same
moment may see the filter half cleared and answer either way for a key being
forgotten, which is what it would have answered a moment either side.

=head2 stats

    my %s = $b->stats;
    # bits, hashes, set, added, seen, estimated, capacity, fill

C<added> counts calls that set something, C<seen> counts calls that found
everything already set. C<fill> is the fraction of bits set and is the number
that says whether the filter is still delivering the rate it was sized for.

Counting the set bits walks the whole array, so this belongs on a status page
rather than in a loop.

=head2 bits, hashes

    my $m = $b->bits;
    my $k = $b->hashes;

=head1 SEE ALSO

L<Shared::Arena>, L<Shared::Arena::Map>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
