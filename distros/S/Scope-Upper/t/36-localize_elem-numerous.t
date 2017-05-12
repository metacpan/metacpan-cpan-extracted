#!perl -T

use strict;
use warnings;

my $n;
BEGIN { $n = 1000; }

use Test::More tests => 3;

use Scope::Upper qw<localize_elem UP>;

our @A = ((0) x $n);

sub setup {
 for (reverse 0 .. ($n-1)) {
  localize_elem '@A', $_ => ($_ + 1) => UP UP;
 }
}

is_deeply  \@A, [ (0) x $n ], '@A was correctly initialized';
{
 setup;
 is_deeply \@A, [ 1 .. $n ],  '@A elements are correctly localized';
}
is_deeply  \@A, [ (0) x $n ], '@A regained its original elements';
