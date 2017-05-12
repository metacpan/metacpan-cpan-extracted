#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use PerlX::Range;
use Test::More;

{
    my $r = (1..10)->by(2);
    is_deeply( \@$r, [1,3,5,7,9] );
    is($r->items, 5);
}

# TODO: {
#    local $TODO = "Should implement the :by() syntax";
#    my $a = 1..10:by(2);
#    is_deeply(\@$a, [1,3,5,7,9]);
#
#    $a = 1..10:by(3);
#    is_deeply(\@$a, [1,4,7,10]);
#
#    $a = 1..10:by(11);
#    is_deeply(\@$a, [1]);
#}

done_testing;
