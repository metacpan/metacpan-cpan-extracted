use Test::More tests => 8;
BEGIN { use_ok('Sub::Assert') };

use strict;
use warnings;
use 5.006;

sub double {
    my $x = shift;
    return $x*2;
}

my $err;
sub darnedtestmodule {
   $err = shift;
}

ok(ref(
assert(
       pre     => '$PARAM[0] > 0',
       post    => '$VOID || $RETURN > $PARAM[0]',
       sub     => 'double',
       context => 'novoid',
       action  => 'darnedtestmodule'
      )
) eq 'CODE', 'assert returns code ref');

$err = undef;
my $d = eval "double(2)";
ok((not defined $err and $d == 4), "assertion did not croak.");

$err = undef;
$d = eval "double(-1)";
ok(defined($err), "assertion carped on unmatched precondition.");

$err = undef;
eval "double(2)";
ok(defined($err), "assertion carped in void context.");

sub faultysqrt {
    my $x = shift;
    return $x**2;
}

assert
       pre    => '$PARAM[0] >= 0',
       post   => '$VOID || $RETURN <= $PARAM[0]',
       sub    => 'faultysqrt',
       action => 'darnedtestmodule';
  
$err = undef;
$d = eval "faultysqrt(3)";
ok(defined($err), "assertion croaked on unmatched postcondition.");


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
 
$err = undef; 
$d = eval "anotherfunc(3, 2);";
ok(1, "function passes");

$err = undef; 
$d = eval "anotherfunc(3, 2, 1);";
ok($err, "assertion croaked on unmatched precondition.");


