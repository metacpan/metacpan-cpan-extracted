use strict;
use Test::More tests => 5;
use Protect::Unwind;

my $i = 0;

is($i++, 0, 'start');

protect {
  is($i++, 1, 'inside protected');
  protect {
    goto ESCAPE;
  } unwind {
    is($i++, 2, 'inside unwind 1');
  };
} unwind {
  is($i++, 3, 'inside unwind 2');
};

ESCAPE:
is($i++, 4, 'all done');
