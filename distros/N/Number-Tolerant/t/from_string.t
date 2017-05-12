use Test::More tests => 7;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

{ # constant (without Constant)
  { # integer
    my $tol = Number::Tolerant->from_string("1012");
    ok(
      ! eval { $tol->isa('Number::Tolerant') },
      "a constant isn't a Number::Tolerant type",
    );
    is($tol, "1012", "constant:  1012");
  }
  { # rational
    my $tol = Number::Tolerant->from_string("10.12");
    ok(
      ! eval { $tol->isa('Number::Tolerant') },
      "a constant isn't a Number::Tolerant type",
    );
    is($tol, "10.12", "constant: 10.12");
  }
}

{ # bad string
  my $tol = eval { Number::Tolerant->from_string("is this thing on?") };
  is($tol, undef, "invalid string: undef");
}

{ # instance method call should die
  my $tol = tolerance(10 => to => 20);
  eval { $tol->from_string("10 to 30"); };
  ok("$@", "from_string is a class method only");
}

