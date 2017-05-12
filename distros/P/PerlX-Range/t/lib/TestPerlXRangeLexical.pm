package TestPerlXRangeLexical;
use strict;
use warnings;
use Test::More;

sub test_range_ref {
    my @a = (1..10);
    is(ref($a[0]), '');
    is(scalar(@a), 10);
}

1;
