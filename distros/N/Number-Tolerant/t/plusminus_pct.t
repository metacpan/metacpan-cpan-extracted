use Test::More 0.88;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

my $guess = Number::Tolerant->new(5 => plus_or_minus_pct => 10);

ok($guess, "created our object");

isa_ok($guess, "Number::Tolerant", " ... ");

is("$guess", "5 +/- 10%", " ... stringifies properly");

ok(0.0 != $guess,         " ... 0.0 isn't equal to it");
ok(4.4 != $guess,         " ... 4.4 isn't equal to it");
ok(4.5 == $guess,         " ... 4.5 is equal to it");
ok(5.0 == $guess,         " ... 5.0 is equal to it");
ok(5.5 == $guess,         " ... 5.5 is equal to it");
ok(5.6 != $guess,         " ... 5.6 isn't equal to it");
ok(6.0 != $guess,         " ... 6.0 isn't equal to it");

ok(     4.4 < $guess,     " ... 4.4 is less than it");
ok(not( 4.5 < $guess),    " ... 4.5 isn't less than it");
ok(not( 5.0 < $guess),    " ... 5.0 isn't less than it");
ok(not( 5.5 < $guess),    " ... 5.5 isn't less than it");
ok(not( 5.6 < $guess),    " ... 5.6 isn't less than it");

ok(not( 4.4 > $guess),    " ... 4.4 isn't more than it");
ok(not( 4.5 > $guess),    " ... 4.5 isn't more than it");
ok(not( 5.0 > $guess),    " ... 5.0 isn't more than it");
ok(not( 5.5 > $guess),    " ... 5.5 isn't more than it");
ok(     5.6 > $guess,     " ... 5.6 is more than it");

is( (4 <=> $guess), -1,   " ... 4 <=> it is -1");
is( (5 <=> $guess),  0,   " ... 5 <=> it is  0");
is( (6 <=> $guess), +1,   " ... 6 <=> it is +1");

# ... and now more of the same, BACKWARDS

ok($guess != 0.0,         " ... it isn't equal to 0.0");
ok($guess != 4.4,         " ... it isn't equal to 4.4");
ok($guess == 4.5,         " ... it is equal to 4.5");
ok($guess == 5.0,         " ... it is equal to 5.0");
ok($guess == 5.5,         " ... it is equal to 5.5");
ok($guess != 5.6,         " ... it isn't equal to 5.6");
ok($guess != 6.0,         " ... it isn't equal to 6.0");

ok(not( $guess < 4.4),    " ... it isn't less than 4.4");
ok(not( $guess < 4.5),    " ... it isn't less than 4.5");
ok(not( $guess < 5.0),    " ... it isn't less than 5.0");
ok(not( $guess < 5.5),    " ... it isn't less than 5.5");
ok(     $guess < 5.6,     " ... it is less than 5.6");

ok(     $guess > 4.4,     " ... it is more than 4.4");
ok(not( $guess > 4.5),    " ... it isn't more than 4.5");
ok(not( $guess > 5.0),    " ... it isn't more than 5.0");
ok(not( $guess > 5.5),    " ... it isn't more than 5.5");
ok(not( $guess > 5.6),    " ... it isn't more than 5.6");

is( ($guess <=> 4), +1,   " ... 4 <=> it is -1");
is( ($guess <=> 5),  0,   " ... 5 <=> it is  0");
is( ($guess <=> 6), -1,   " ... 6 <=> it is +1");

{ # from_string
  my $tol = Number::Tolerant->from_string("10 +/- 10%");
  isa_ok($tol, 'Number::Tolerant');
  is($tol, "10 +/- 10%", " ... stringifies as plus_or_minus_pct");
}

{ # with a rational
  my $tol = Number::Tolerant->new(1_000 => plus_or_minus_pct => '1/2');
  isa_ok($tol, 'Number::Tolerant');
  ok($tol !=  994, " ...  994 not in $tol");
  ok($tol ==  995, " ...  995  is in $tol");
  ok($tol ==  996, " ...  996  is in $tol");
  ok($tol == 1004, " ... 1004  is in $tol");
  ok($tol == 1005, " ... 1005  is in $tol");
  ok($tol != 1006, " ... 1006 not in $tol");
}

done_testing;
