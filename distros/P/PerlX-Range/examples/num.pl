#!/usr/bin/env perl
use strict;
use warnings;
# use 5.010;
use PerlX::Range;

my $a= 1..100;

# should only print 1, 5, 9
$a->each(
    sub {
        return 0 if $_ > 10;
        say $_;
    }
);
