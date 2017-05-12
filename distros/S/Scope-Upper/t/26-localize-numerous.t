#!perl -T

use strict;
use warnings;

my $n;
BEGIN { $n = 1000; }

use Test::More tests => 3;

use Scope::Upper qw<localize UP>;

our $x = 0;
our $z = $n;

sub setup {
 for (1 .. $n) {
  localize *x, *z => UP UP;
 }
}

is $x,  0,  '$x is correctly initialized';
{
 setup;
 is $x, $n, '$x is correctly localized';
}
is $x,  0,  '$x regained its original value';
