use strict;
use Test::More tests => 3;
use Protect::Unwind;

my $i = 0;

is($i++, 0, 'start');

protect {
  is($i++, 1, 'inside protected');
  exit;
} unwind {
  is($i++, 2, 'inside after');
};
