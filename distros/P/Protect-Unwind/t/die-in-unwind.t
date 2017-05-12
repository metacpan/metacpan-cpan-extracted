use strict;
use Test::More tests => 5;
use Protect::Unwind;

my $i = 0;

is($i++, 0, 'start');

eval {
  protect {
    protect {
      is($i++, 1, 'inside protected');
      goto ESCAPE;
    } unwind {
      is($i++, 2, 'inside unwind 1');
      die "hello";
    };
  } unwind {
    is($i++, 3, 'inside unwind 2');
  };
};

die "shouldn't get here";

ESCAPE:
is($i++, 4, 'all done');
