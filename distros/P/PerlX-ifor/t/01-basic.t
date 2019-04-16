#!perl

use strict;
use warnings;
use Test::More 0.98;

use PerlX::ifor;
use Range::Iter qw(range_iter);

my @ary;
ifor { push @ary, $_ } range_iter("a", "j");
is_deeply(\@ary, ["a".."j"]);

DONE_TESTING:
done_testing;
