use strict;
use Test::More tests => 5;
use Protect::Unwind;

my $i = 0;

is($i++, 0, 'start');

eval {
  protect {
    is($i++, 1, 'inside protected');
    die "ESCAPE";
  } unwind {
    is($i++, 2, 'inside after');
  };
};

ok($@, 'error caught');

is($i++, 3, 'all done');
