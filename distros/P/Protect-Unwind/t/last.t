use strict;
use Test::More tests => 4;
use Protect::Unwind;

my $i = 0;

is($i++, 0, 'start');

no warnings; ## Exiting subroutine via last at t/last.t 

ESCAPE: while(1) {
  protect {
    is($i++, 1, 'inside protected');
    last ESCAPE;
  } unwind {
    is($i++, 2, 'inside after');
  };
};

is($i++, 3, 'all done');
