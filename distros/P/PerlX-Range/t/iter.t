#!/usr/bin/env perl -w
use strict;
use warnings;
use 5.010;
use Test::More;
use PerlX::Range;
use PerlX::MethodCallWithBlock;

my $a = 1..1000;

my $b = 1;
$a->each {
    my ($self, $x) = @_;
    return 0 if $b == 5;        # a defined false value.

    is($self, $a);
    is($_, $b);
    is($_, $x);
    $b++;
};
is($a, "1..1000", '$a is 1..1000');
is($b, 5, "but only ran only 5 iterations");

done_testing;
