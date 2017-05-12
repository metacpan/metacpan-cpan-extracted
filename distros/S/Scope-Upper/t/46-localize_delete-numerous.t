#!perl -T

use strict;
use warnings;

my $n;
BEGIN { $n = 1000; }

use Test::More tests => 3;

use Scope::Upper qw<localize_delete UP>;

our @A = (1 .. $n);

sub setup {
 for (reverse 0 .. ($n-1)) {
  localize_delete '@A', $_ => UP UP;
 }
}

is_deeply  \@A, [ 1 .. $n ], '@A was correctly initialized';
{
 setup;
 is_deeply \@A, [ ],         '@A is empty inside the block';
}
is_deeply  \@A, [ 1 .. $n ], '@A regained its elements';
