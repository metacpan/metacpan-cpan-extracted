use strict;
use warnings;

# Google Chart API is way cool.  Here's how you can implement their extended
# encoding. -- rjbs, 2008-04-18

use Test::More tests => 8;

use Number::Nary;

my ($c, $d) = n_codec(
  join('', ('A'..'Z', 'a'..'z', 0..9, '-', '.')),
  { postencode => sub { length($_[0]) % 2 ? "A$_[0]" : $_[0] } }
);

my @pairs = (
  [ qw(    7 AH) ],
  [ qw(  133 CF) ],
  [ qw( 3975 -H) ],
  [ qw( 4037 .F) ],
);

for my $pair (@pairs) {
  ok($pair->[0] == $d->($pair->[1]), "$pair->[0] == dec($pair->[1])");
  ok($pair->[1] eq $c->($pair->[0]), "$pair->[1] eq enc($pair->[0])");
}
