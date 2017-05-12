use Test::More tests => 58;

use strict;
use warnings;

use Number::Tolerant;
use Number::Tolerant::Constant;

{ # constant (with Constant)
  { # integer
    my $tol = Number::Tolerant->from_string("1012");
    isa_ok($tol, 'Number::Tolerant', "real, blessed constant tolerance");
    is($tol, "1012", "constant:  1012");
  }
  { # rational
    my $tol = Number::Tolerant->from_string("10.12");
    isa_ok($tol, 'Number::Tolerant', "real, blessed constant tolerance");
    is($tol, "10.12", "constant: 10.12");
  }
}

{ # test parse
  { # success!
    my $tol = Number::Tolerant->from_string("5");
    isa_ok($tol, 'Number::Tolerant', "the number 5");
  }
  { # failures!
    for ("0=0", '-1-', 'six') {
      {
        my $tol = eval { Number::Tolerant->from_string($_) };
        ok(!$tol, "intolerable string!");
      }
      {
        my $tol = eval { tolerance($_) };
        ok(!$tol, "intolerable param!");
      }
    }
    is(eval { tolerance(10,20,30) }, undef, "bogus tolerance");
  }
}

my $guess = Number::Tolerant->new(5);

ok($guess, "created our object");

isa_ok($guess, 'Number::Tolerant', " ... ");

is("$guess", "5",         " ... stringifies properly");
is(0+$guess, 5,           " ... numifies properly");

ok(0.0 != $guess,         " ... 0.0 isn't equal to it");
ok(4.4 != $guess,         " ... 4.4 isn't equal to it");
ok(4.5 != $guess,         " ... 4.5 isn't equal to it");
ok(5.0 == $guess,         " ... 5.0 is equal to it");
ok(5.5 != $guess,         " ... 5.5 isn't equal to it");
ok(5.6 != $guess,         " ... 5.6 isn't equal to it");
ok(6.0 != $guess,         " ... 6.0 isn't equal to it");

ok(     4.4 < $guess,     " ... 4.4 is less than it");
ok(     4.5 < $guess,     " ... 4.5 is less than it");
ok(not( 5.0 < $guess),    " ... 5.0 isn't less than it");
ok(not( 5.5 < $guess),    " ... 5.5 isn't less than it");
ok(not( 5.6 < $guess),    " ... 5.6 isn't less than it");

ok(not( 4.4 > $guess),    " ... 4.4 isn't more than it");
ok(not( 4.5 > $guess),    " ... 4.5 isn't more than it");
ok(not( 5.0 > $guess),    " ... 5.0 isn't more than it");
ok(     5.5 > $guess,     " ... 5.5 is more than it");
ok(     5.6 > $guess,     " ... 5.6 is more than it");

is( (4 <=> $guess), -1,   " ... 4 <=> it is -1");
is( (5 <=> $guess),  0,   " ... 5 <=> it is  0");
is( (6 <=> $guess), +1,   " ... 6 <=> it is +1");

# ... and now more of the same, BACKWARDS

ok($guess != 0.0,         " ... it isn't equal to 0.0");
ok($guess != 4.4,         " ... it isn't equal to 4.4");
ok($guess != 4.5,         " ... it isn't equal to 4.5");
ok($guess == 5.0,         " ... it is equal to 5.0");
ok($guess != 5.5,         " ... it isn't equal to 5.5");
ok($guess != 5.6,         " ... it isn't equal to 5.6");
ok($guess != 6.0,         " ... it isn't equal to 6.0");

ok(not( $guess < 4.4),    " ... it isn't less than 4.4");
ok(not( $guess < 4.5),    " ... it isn't less than 4.5");
ok(not( $guess < 5.0),    " ... it isn't less than 5.0");
ok(     $guess < 5.5,     " ... it is less than 5.5");
ok(     $guess < 5.6,     " ... it is less than 5.6");

ok(     $guess > 4.4,     " ... it is more than 4.4");
ok(     $guess > 4.5,     " ... it is more than 4.5");
ok(not( $guess > 5.0),    " ... it isn't more than 5.0");
ok(not( $guess > 5.5),    " ... it isn't more than 5.5");
ok(not( $guess > 5.6),    " ... it isn't more than 5.6");

is( ($guess <=> 4), +1,   " ... 4 <=> it is -1");
is( ($guess <=> 5),  0,   " ... 5 <=> it is  0");
is( ($guess <=> 6), -1,   " ... 6 <=> it is +1");

{
  my $const = Number::Tolerant->from_string("1");
  ok(ref($const), "1 as tolerance is object with Constant in effect");
}

{
  Number::Tolerant::Constant->_disable;
  my $const = Number::Tolerant->from_string("1");
  ok(
    ! eval { $const->isa('Number::Tolerant') },
    "1 as tolerance is not an N::T object after 'N::T::C->_disable'"
  );
}
