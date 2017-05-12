use Test::More;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

{ # x_to_y & x_to_y
  my $demand = Number::Tolerant->new(40 => to => 60);
  my $offer  = Number::Tolerant->new(30 => to => 50);

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 <= x <= 50', ' ... stringifies');

  is($range->{min},      40, ' ... minimum : 40');
  is($range->{max},      50, ' ... maximum : 50');
}

{ # x_to_y & x_or_more
  my $demand = Number::Tolerant->new(40 => 'or_more');
  my $offer  = Number::Tolerant->new(30 => to => 50);

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 <= x <= 50', ' ... stringifies');

  is($range->{min},      40, ' ... minimum : 40');
  is($range->{max},      50, ' ... maximum : 50');
}

{ # x_or_more & x_or_more
  my $demand = Number::Tolerant->new(40 => 'or_more');
  my $offer  = Number::Tolerant->new(30 => 'or_more');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 <= x', ' ... stringifies');

  is($range->{min},         40, ' ... minimum : 40');
  is($range->{max},      undef, ' ... maximum : undef');
}

{ # x_or_less & x_or_less
  my $demand = Number::Tolerant->new(40 => 'or_less');
  my $offer  = Number::Tolerant->new(30 => 'or_less');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", 'x <= 30', ' ... stringifies');

  is($range->{min},      undef, ' ... minimum : undef');
  is($range->{max},         30, ' ... maximum : 30');
}

{ # x_or_more & more_than_x
  my $demand = Number::Tolerant->new(40 => 'or_more');
  my $offer  = Number::Tolerant->new(30 => 'more_than');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 <= x', ' ... stringifies');

  is($range->{min},         40, ' ... minimum : undef');
  is($range->{max},      undef, ' ... maximum : 30');
}

{ # more_than_x & x_or_more
  my $demand = Number::Tolerant->new(30 => 'or_more');
  my $offer  = Number::Tolerant->new(40 => 'more_than');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $offer & $demand;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 < x', ' ... stringifies');

  is($range->{min},         40, ' ... minimum : 40');
  is($range->{max},      undef, ' ... maximum : undef');
}

{ # x_or_more & more_than_x
  my $demand = Number::Tolerant->new(30 => 'or_more');
  my $offer  = Number::Tolerant->new(40 => 'more_than');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 < x', ' ... stringifies');

  is($range->{min},         40, ' ... minimum : 40');
  is($range->{max},      undef, ' ... maximum : undef');
}

{ # x_or_less & less_than_x
  my $demand = Number::Tolerant->new(40 => 'or_less');
  my $offer  = Number::Tolerant->new(30 => 'less_than');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", 'x < 30', ' ... stringifies');

  is($range->{min},      undef, ' ... minimum : undef');
  is($range->{max},         30, ' ... maximum : 30');
}

{ # less_than_x & x_or_less
  my $demand = Number::Tolerant->new(40 => 'or_less');
  my $offer  = Number::Tolerant->new(30 => 'less_than');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $offer & $demand;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", 'x < 30', ' ... stringifies');

  is($range->{min},      undef, ' ... minimum : undef');
  is($range->{max},         30, ' ... maximum : 30');
}

{ # less_than_x & more_than_x
  my $demand = Number::Tolerant->new(40 => 'less_than');
  my $offer  = Number::Tolerant->new(30 => 'more_than');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range",   '30 < x < 40', ' ... stringifies');

  is($range->{min},         30, ' ... minimum : 30');
  is($range->{max},         40, ' ... maximum : 40');
  is($range->{exclude_min},  1, ' ... exclude minimum');
  is($range->{exclude_max},  1, ' ... exclude maximum');

  ok($range == 31,     "31 is inside range");
  ok($range != 30,     "30 is outside range");

  ok($range == 39,     "39 is inside range");
  ok($range != 40,     "40 is ouside range");
}

{ # x_to_y & x_or_less
  my $demand = Number::Tolerant->new(40 => to => 60);
  my $offer  = Number::Tolerant->new(50 => 'or_less');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 <= x <= 50', ' ... stringifies');

  is($range->{min},      40, ' ... minimum : 40');
  is($range->{max},      50, ' ... maximum : 50');
}

{ # x_or_less & x_to_y
  my $demand = Number::Tolerant->new(40 => to => 60);
  my $offer  = Number::Tolerant->new(50 => 'or_less');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $offer & $demand;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 <= x <= 50', ' ... stringifies');

  is($range->{min},      40, ' ... minimum : 40');
  is($range->{max},      50, ' ... maximum : 50');
}

{ # x_to_y & infinite
  my $demand = Number::Tolerant->new(40 => to => 60);
  my $offer  = Number::Tolerant->new('infinite');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '40 <= x <= 60', ' ... stringifies');

  is($range->{min},      40, ' ... minimum : 40');
  is($range->{max},      60, ' ... maximum : 50');
}

{ # infinite & infinite
  my $demand = Number::Tolerant->new('infinite');
  my $offer  = Number::Tolerant->new('infinite');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", 'any number', ' ... stringifies');

  is($range->{min},      undef, ' ... minimum : undef');
  is($range->{max},      undef, ' ... maximum : undef');
}

{ # min = 0 for first limit
  my $demand = Number::Tolerant->new(0 => 'or_more');
  my $offer  = Number::Tolerant->new(10 => 'or_less');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '0 <= x <= 10', ' ... stringifies');

  is($range->{min},       0, ' ... minimum :  0');
  is($range->{max},      10, ' ... maximum : 10');
}

{ # max = 0 for first limit
  my $demand = Number::Tolerant->new(0 => 'or_less');
  my $offer  = Number::Tolerant->new(-5 => 'or_more');

  isa_ok($demand, 'Number::Tolerant');
  isa_ok($offer,  'Number::Tolerant');

  my $range = $demand & $offer;

  isa_ok($range,   'Number::Tolerant', 'intersection');

  is("$range", '-5 <= x <= 0', ' ... stringifies');

  is($range->{min},      -5, ' ... minimum : -5');
  is($range->{max},       0, ' ... maximum :  0');
}

done_testing;
