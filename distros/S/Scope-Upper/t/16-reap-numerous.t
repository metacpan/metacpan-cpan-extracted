#!perl -T

use strict;
use warnings;

my $n;
BEGIN { $n = 1000; }

use Test::More tests => $n;

use Scope::Upper qw<reap UP>;

my $count;

sub setup {
 for my $i (reverse 1 .. $n) {
  reap {
   is $count, $i, "$i-th destructor called at the right time";
   ++$count;
  } UP UP;
 }
}

$count = $n + 1;

{
 setup;
 $count = 1;
}
