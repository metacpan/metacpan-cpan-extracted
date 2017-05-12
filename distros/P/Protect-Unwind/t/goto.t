use strict;
use Test::More tests => 4;
use Protect::Unwind;

my $i = 0;

is($i++, 0, 'start');

protect {
  is($i++, 1, 'inside protected');
  goto ESCAPE;
} unwind {
  is($i++, 2, 'inside after');
};

ESCAPE:
is($i++, 3, 'all done');
