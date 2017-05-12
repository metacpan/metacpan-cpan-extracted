use Test::More tests => 7;
BEGIN { use_ok('Sub::Assert::Nothing') };


use strict;
use warnings;
use 5.006;

sub double {
    my $x = shift;
    return $x*2;
}

ok(ref(
assert(
       pre     => '$PARAM[0] > 0',
       post    => '$VOID || $RETURN > $PARAM[0]',
       sub     => 'double',
       context => 'novoid',
       action  => 'darnedtestmodule'
      )
) ne 'CODE', 'assert (nothing) returns *nothing*');

my $d = double(2);
ok(1, "assertion did not croak.");

$d = double(-1);
ok(1, "assertion carped on unmatched precondition.");

double(2);
ok(1, "assertion didn't complain now either.");

sub faultysqrt {
    my $x = shift;
    return $x**2;
}

assert
       pre    => '$PARAM[0] >= 0',
       post   => '$VOID || $RETURN <= $PARAM[0]',
       sub    => 'faultysqrt',
       action => 'darnedtestmodule';
  
$d = faultysqrt(3);
ok(1, "assertion did not complain this time.");

sub anotherfunc {
  my $x = shift;
  my $y = shift;
  return abs($x * $y);
}

assert
       pre    => [
        '@PARAM == 2',
       ],
       post   => [
        '!$VOID',
        '$RETURN > 0',
        '$PARAM[0]*$PARAM[1]-1.e-12 < $RETURN',
        '$PARAM[0]*$PARAM[1]+1.e-12 > $RETURN',
       ],
       sub    => 'anotherfunc',
       action => 'darnedtestmodule';
  
$d = anotherfunc(3, 2);
ok(1, "assertion did not complain this time.");


