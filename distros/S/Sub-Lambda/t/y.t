#!perl -T

use strict;
use warnings;
use Test::Simple tests => 20;
use Sub::Lambda;

sub factorial {
    my ($n) = @_;
    my $r = 1;
    for (my $i = 2; $i <= $n; $i++) { $r*=$i; }
    return $r;
}

my $fac = fn f => fn n => q{ ($n<1) ? 1 : $n*$f->($n-1) };

my $Y   = fn m => ap(
 (fn f => ap m => fn a => ap f => f => a => ()) =>
 (fn f => ap m => fn a => ap f => f => a => ())
);

for (my $n = 1; $n <= 20; $n++) {
    ok((factorial($n) == $Y->($fac)->($n)), "Y fac ($n) = $n!");
}


