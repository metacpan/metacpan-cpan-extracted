use Test::More tests => 32;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }
BEGIN { use_ok("Number::Tolerant::Union"); }

{ # tol | constant
  my $alpha = Number::Tolerant->new(4.5  => to => 5.25);

  isa_ok($alpha, 'Number::Tolerant');

  my $choice = $alpha | 7;

  isa_ok($choice,   'Number::Tolerant::Union', 'union');

  ok(5 == $choice, ' ... 5 == $union');
  ok(6 != $choice, ' ... 6 != $union');
  ok(7 == $choice, ' ... 7 == $union');
  ok(8 != $choice, ' ... 8 != $union');
}

{ # tol | tol | constant
  my $alpha = Number::Tolerant->new(4.5  => to => 5.25);
  my $beta  = Number::Tolerant->new(5.75 => to => 6.25);

  isa_ok($alpha, 'Number::Tolerant');
  isa_ok($beta,  'Number::Tolerant');

  my $choice = $alpha | $beta | 7;

  isa_ok($choice,   'Number::Tolerant::Union', 'union');

  ok(5 == $choice, ' ... 5 == $union');
  ok(6 == $choice, ' ... 6 == $union');
  ok(7 == $choice, ' ... 7 == $union');
  ok(8 != $choice, ' ... 8 != $union');
}

{ # union | union
  my $alpha = Number::Tolerant->new(4.5  => to => 5.25);
  my $beta  = Number::Tolerant->new(5.75 => to => 6.25);

  isa_ok($alpha, 'Number::Tolerant');
  isa_ok($beta,  'Number::Tolerant');

  my $gamma = Number::Tolerant->new(6 => to => 7);
  my $delta = Number::Tolerant->new(1 => to => 2);

  isa_ok($gamma, 'Number::Tolerant');
  isa_ok($delta, 'Number::Tolerant');

  my $c1 = $alpha | $beta;
  my $c2 = $gamma | $delta;

  isa_ok($c1, 'Number::Tolerant::Union', 'union');
  isa_ok($c2, 'Number::Tolerant::Union', 'union');

  my $choice = $c1 | $c2;

  isa_ok($choice,  'Number::Tolerant::Union', 'union');

  ok(5 == $choice, ' ... 5 == $union');
  ok(6 == $choice, ' ... 6 == $union');
  ok(7 == $choice, ' ... 7 == $union');
  ok(8 != $choice, ' ... 8 != $union');
}

{ # union(x..y) like Number::Range

  my $range = Number::Tolerant::Union->new(1..10, 15..20);

  isa_ok($range, 'Number::Tolerant::Union');

  ok( 5.0 == $range, ' ...  5.0 == $union');
  ok( 5.5 != $range, ' ...  5.5 != $range');
  ok( 6.0 == $range, ' ...  6.0 == $union');
  ok(11.0 != $range, ' ... 11.0 == $union');
  ok(15.0 == $range, ' ... 15.0 != $union');
}
