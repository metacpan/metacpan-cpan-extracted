#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More skip_all => "Need to re-implement the :by() syntax";
use PerlX::Range;

my $a = 1..*:by(2);

my @r = ();
$a->each(sub {
             return 0 if $_ > 10;
             push @r, $_;
         });

is_deeply(\@r, [1,3,5,7,9], "1..*:by(2)");

done_testing;
