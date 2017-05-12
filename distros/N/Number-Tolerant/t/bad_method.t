use Test::More tests => 22;

use strict;
use warnings;

BEGIN { use_ok("Number::Tolerant"); }

## this test right here... it used to test for a bad method
## but it ain't like that no more
## a tolerance of a number is that number
## and that's just the way it is.
is(
  Number::Tolerant->new(5),
  5,
  "constants return constants"
);

is(
  eval { Number::Tolerant->new(5 => 'thingie' => 0.5) },
  undef,
  "there is no 'thingie' method"
);

is(
  eval { Number::Tolerant->new(5 => 'to') },
  undef,
  "'to' requires two values"
);

is(
  eval { Number::Tolerant->new(5 => to => 'life') },
  undef,
  "'to' requires two numbers"
);

is(
  eval { Number::Tolerant->new(5 => 'plus_or_minus') },
  undef,
  "'plus_or_minus' requires two values"
);

is(
  eval { Number::Tolerant->new(5 => 'plus_or_minus_pct') },
  undef,
  "'plus_or_minus_pct' requires two values"
);

is(
  eval { Number::Tolerant->new(5 => 'plus_or_minus' => 'zero') },
  undef,
  "'plus_or_minus' requires two numbers"
);

is(
  eval { Number::Tolerant->new(5 => 'plus_or_minus_pct' => 'zero') },
  undef,
  "'plus_or_minus_pct' requires two numbers"
);

is(
  eval { Number::Tolerant->new(five => 'exactly') },
  undef,
  "invalid two-arg construction"
);

is(
  eval { Number::Tolerant->new(just_about => 12) },
  undef,
  "invalid two-arg construction"
);

is(
  eval { Number::Tolerant->new() },
  undef,
  "at least one param required"
);

is(
  eval { Number::Tolerant->new('things') },
  undef,
  "single, non-numeric argument"
);

is(
  eval { Number::Tolerant->new(undef) },
  undef,
  "single, undefined argument"
);

is(
  eval { Number::Tolerant->new('') },
  undef,
  "single, pseudo-numeric argument"
);

is(
  eval { Number::Tolerant->new(undef , 'to' , undef) },
  undef,
  "undef-undef range not valid (should it be?)"
);

is(
  eval { Number::Tolerant->new('string' => 'broken' => 'args') },
  undef,
  "three invalid params"
);

# let's pander to offset's four-parters:
is(
  eval { Number::Tolerant->new('string' => 'broken' => 'args' => 'fourway') },
  undef,
  "four lousy params"
);

is(
  eval { Number::Tolerant->new(10 => 'broken' => 'args' => 'fourway') },
  undef,
  "number, then three invalid params"
);

is(
  eval { Number::Tolerant->new(10 => 'offset' => 'args' => 'fourway') },
  undef,
  "10 offset blah blah",
);

is(
  eval { Number::Tolerant->new(10 => 'offset' => 3 => 'fourway') },
  undef,
  "10 offset number blah"
);

is(
  eval { Number::Tolerant->new(10 => 'offset' => undef => 4) },
  undef,
  "10 offset undef number"
);
