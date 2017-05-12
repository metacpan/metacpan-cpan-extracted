use Test::More tests => 84;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

my $guess = Number::Tolerant->new(more_than => 5);

ok($guess, "created our object: more than 5");

isa_ok($guess, "Number::Tolerant", " ... ");

is("$guess", "5 < x",     " ... stringifies properly");

ok(0.0 != $guess,         " ... 0.0 isn't equal to it");
ok(4.4 != $guess,         " ... 4.4 isn't equal to it");
ok(4.5 != $guess,         " ... 4.5 isn't equal to it");
ok(5.0 != $guess,         " ... 5.0 isn't equal to it");
ok(5.5 == $guess,         " ... 5.5 is equal to it");
ok(5.6 == $guess,         " ... 5.6 is equal to it");
ok(6.0 == $guess,         " ... 6.0 is equal to it");

ok(     4.4 < $guess,     " ... 4.4 is less than it");
ok(     4.5 < $guess,     " ... 4.5 is less than it");
ok(     5.0 < $guess,     " ... 5.0 is less than it");
ok(not( 5.5 < $guess),    " ... 5.5 isn't less than it");
ok(not( 5.6 < $guess),    " ... 5.6 isn't less than it");

ok(     4.4 <= $guess,    " ... 4.4 is less than or equal to it");
ok(     4.5 <= $guess,    " ... 4.5 is less than or equal to it");
ok(     5.0 <= $guess,    " ... 5.0 is less than or equal to it");
ok(     5.5 <= $guess,    " ... 5.5 is less than or equal to it");
ok(     5.6 <= $guess,    " ... 5.6 is less than or equal to it");

ok(not( 4.4 > $guess),    " ... 4.4 isn't more than it");
ok(not( 4.5 > $guess),    " ... 4.5 isn't more than it");
ok(not( 5.0 > $guess),    " ... 5.0 isn't more than it");
ok(not( 5.5 > $guess),    " ... 5.5 isn't more than it");
ok(not( 5.6 > $guess),    " ... 5.6 isn't more than it");

ok(not( 4.4 >= $guess),   " ... 4.4 isn't more than or equal to it");
ok(not( 4.5 >= $guess),   " ... 4.5 isn't more than or equal to it");
ok(not( 5.0 >= $guess),   " ... 5.0 isn't more than or equal to it");
ok(     5.5 >= $guess,    " ... 5.5 is more than or equal to it");
ok(     5.6 >= $guess,    " ... 5.6 is more than or equal to it");

is( (0.0 <=> $guess), -1, " ... 0.0 <=> it is -1");
is( (4.4 <=> $guess), -1, " ... 4.4 <=> it is -1");
is( (4.5 <=> $guess), -1, " ... 4.5 <=> it is -1");
is( (5.0 <=> $guess), -1, " ... 5.0 <=> it is -1");
is( (5.5 <=> $guess),  0, " ... 5.5 <=> it is  0");
is( (5.6 <=> $guess),  0, " ... 5.6 <=> it is  0");
is( (6.0 <=> $guess),  0, " ... 6.0 <=> it is  0");
is( (4 <=> $guess), -1,   " ...   4 <=> it is -1");
is( (5 <=> $guess), -1,   " ...   5 <=> it is -1");
is( (6 <=> $guess),  0,   " ...   6 <=> it is  0");

# ... and now more of the same, BACKWARDS

ok($guess != 0.0,         " ... it isn't equal to 0.0");
ok($guess != 4.4,         " ... it isn't equal to 4.4");
ok($guess != 4.5,         " ... it isn't equal to 4.5");
ok($guess != 5.0,         " ... it isn't equal to 5.0");
ok($guess == 5.5,         " ... it is equal to 5.5");
ok($guess == 5.6,         " ... it is equal to 5.6");
ok($guess == 6.0,         " ... it is equal to 6.0");

ok(not( $guess < 4.4),    " ... it isn't less than 4.4");
ok(not( $guess < 4.5),    " ... it isn't less than 4.5");
ok(not( $guess < 5.0),    " ... it isn't less than 5.0");
ok(not( $guess < 5.5),    " ... it isn't less than 5.5");
ok(not( $guess < 5.6),    " ... it isn't less than 5.6");

ok(not( $guess <= 4.4),   " ... it isn't less than or equal 4.4");
ok(not( $guess <= 4.5),   " ... it isn't less than or equal 4.5");
ok(not( $guess <= 5.0),   " ... it isn't less than or equal 5.0");
ok(     $guess <= 5.5,    " ... it is less than or equal 5.5");
ok(     $guess <= 5.6,    " ... it is less than or equal 5.6");

ok(     $guess > 4.4,     " ... it is more than 4.4");
ok(     $guess > 4.5,     " ... it is more than 4.5");
ok(     $guess > 5.0,     " ... it is more than 5.0");
ok(not( $guess > 5.5),    " ... it isn't more than 5.5");
ok(not( $guess > 5.6),    " ... it isn't more than 5.6");

ok(     $guess >= 4.4,    " ... it is more than or equal 4.4");
ok(     $guess >= 4.5,    " ... it is more than or equal 4.5");
ok(     $guess >= 5.0,    " ... it is more than or equal 5.0");
ok(     $guess >= 5.5,    " ... it is more than or equal 5.5");
ok(     $guess >= 5.6,    " ... it is more than or equal 5.6");

is( ($guess <=> 0.0), +1, " ... 0.0 <=> it is +1");
is( ($guess <=> 4.4), +1, " ... 4.4 <=> it is +1");
is( ($guess <=> 4.5), +1, " ... 4.5 <=> it is +1");
is( ($guess <=> 5.0), +1, " ... 5.0 <=> it is +1");
is( ($guess <=> 5.5),  0, " ... 5.5 <=> it is  0");
is( ($guess <=> 5.6),  0, " ... 5.6 <=> it is  0");
is( ($guess <=> 6.0),  0, " ... 6.0 <=> it is  0");
is( ($guess <=> 4), +1,   " ...   4 <=> it is +1");
is( ($guess <=> 5), +1,   " ...   5 <=> it is +1");
is( ($guess <=> 6), 0,    " ...   6 <=> it is  0");

{ # from_string
  { # prosaic
    my $tol = Number::Tolerant->from_string("more than 10");
    isa_ok($tol, 'Number::Tolerant');
    is($tol, "10 < x", "or_more");
  }
  { # algebraic
    my $tol = Number::Tolerant->from_string("> 10");
    isa_ok($tol, 'Number::Tolerant');
    is($tol, "10 < x", "more_than");
  }
  { # reverse algebraic
    my $tol = Number::Tolerant->from_string("10 < x");
    isa_ok($tol, 'Number::Tolerant');
    is($tol, "10 < x", "more_than");
  }
}
