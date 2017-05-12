use strict;
use warnings;

use Test::Tester;

use Test::More;
use Test::Tolerant;


check_test(
  sub { is_tol(5, 'x > 4'); },
  {
    ok   => 1,
    name => '',
    diag => '',
  },
  "successful comparison"
);

check_test(
  sub { is_tol(5, 'x > 5'); },
  {
    ok   => 0,
    name => '',
    diag => <<END_DIAG,
given value is below acceptable tolerances
    have: 5
    want: 5 < x
END_DIAG
  },
  "short, failed comparison"
);

check_test(
  sub { is_tol(5, [ qw(more_than 5) ]); },
  {
    ok   => 0,
    name => '',
    diag => <<END_DIAG,
given value is below acceptable tolerances
    have: 5
    want: 5 < x
END_DIAG
  },
  "short, failed comparison"
);

check_test(
  sub { is_tol(5, Number::Tolerant->new(qw(more_than 5))); },
  {
    ok   => 0,
    name => '',
    diag => <<END_DIAG,
given value is below acceptable tolerances
    have: 5
    want: 5 < x
END_DIAG
  },
  "short, failed comparison"
);

done_testing;
