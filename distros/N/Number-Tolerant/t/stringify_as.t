use Test::More tests => 9;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

{ # plusminus
  my $tol = tolerance(10 => plus_or_minus => 2);
  is($tol->stringify, "10 +/- 2", "plus_or_minus");
  TODO: { local $TODO = "stringify_as not soup yet";
    is(
      $tol->stringify_as('plus_or_minus_pct'),
      "10 +/- 20%",
      "plus_or_minus as _pct"
    );
  }
}

{ # plusminus_pct
  my $tol = tolerance(10 => plus_or_minus_pct => 10);
  is($tol->stringify, "10 +/- 10%", "plus_or_minus_pct");
  TODO: { local $TODO = "stringify_as not soup yet";
    is(
      $tol->stringify_as('plus_or_minus'),
      "10 +/- 1",
      "plus_or_minus_pct as plus_or_minus"
    );
  }
}

{ # or_less
  my $tol = tolerance(10 => 'or_less');
  is($tol->stringify, "x <= 10", "or_less");
}

{ # or_more
  my $tol = tolerance(10 => 'or_more');
  is($tol->stringify, "10 <= x", "or_more");
}

{ # x_to_y
  my $tol = tolerance(8 => to => 12);
  is($tol->stringify, "8 <= x <= 12", "to");
}


{ # infinite
  my $tol = tolerance("infinite");
  is($tol->stringify, "any number", "infinite");
}
