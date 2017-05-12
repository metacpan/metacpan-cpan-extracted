#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use PerlX::Range;
use Test::More skip_all => "Need to re-implement the 1..* syntax";

my $a = 1..*;

my $b = 0;
$a->each(sub {
    return 0 if $_ > 5;
    ++$b;
});
is($b, 5, 'only done 5 iteration');

done_testing;
