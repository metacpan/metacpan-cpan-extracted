#!perl -w
use strict;
use Term::HiliteDiff;

my $o = Term::HiliteDiff->new;
my $until = 60 + time;

# Loop for a minute to give the profiler time to notice what's slow.
my $diff;
until ( time() >= $until ) {
    $diff = $o->hilite_diff( [ rand, rand, 'A' ] );
    last;
}
