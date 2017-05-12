use Test::More tests => 9;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

{
  my $range = Number::Tolerant->new(5 => to => 9);

  isa_ok($range, 'Number::Tolerant');

  is($range & 5.0,   5.0, ' ... $range & 5.0 == 5.0');
  is($range & 5.0,   5.0, ' ... 5.0 & $range == 5.0');
  is($range & 6.5,   6.5, ' ... $range & 6.5 == 6.5');
  is($range & 6.5,   6.5, ' ... 6.5 & $range == 6.5');

  ok(! eval { $range & 1.0 }, ' ... 6.5 & $range == exception');
}

{
  my $range = Number::Tolerant->new(-5 => to => 5);

  isa_ok($range, 'Number::Tolerant');

  is($range & 0, 0, ' ... $range & 0 == 0');
}
