#! /usr/bin/env perl

use v5.22;
use warnings;

use Multi::Dispatch;

multi fact1 ($n :where(0)) { 1 }
multi fact1 ($n)           { $n * fact1($n-1) }

multi fact2 ($n == 0) { 1 }
multi fact2 ($n)      { $n * fact2($n-1) }

multi fact3 (0)  { 1 }
multi fact3 ($n) { $n * fact3($n-1) }

for my $n (0..10) {
    say "$n! = ", fact1($n);
    say "$n! = ", fact2($n);
    say "$n! = ", fact3($n);
}


