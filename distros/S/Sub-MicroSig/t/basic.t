#!perl -T
use strict;
use warnings;

use Test::More tests => 8;

BEGIN { use_ok('Sub::MicroSig'); }

{
  # These tests could probably be removed, but during development of PVM and
  # MicroSig, HDP and RJBS had different expectations.  This reminds RJBS which
  # ones went into production.
  use Params::Validate::Micro qw(micro_validate);

  is_deeply(
    micro_validate({ foo => 10 }, "foo"),
    { foo => 10 },
    "pv_m is what we expect for named",
  );

  is_deeply(
    micro_validate([ 10 ], "foo"),
    { foo => 10 },
    "pv_m is what we expect for positional",
  );
}

sub with_params :Sig(foo) {
  return @_;
}

is_deeply(
  with_params({ foo => 20 }),
  { foo => 20 },
  "named params to simple sig"
);

is_deeply(
  with_params([ 20 ]),
  { foo => 20 },
  "positional params to simple sig"
);

eval { with_params(10); };
like($@, qr/args to microsig'd sub/, "a plain scalar isn't an OK arg");

eval { with_params([1], [2]); };
like($@, qr/args to microsig'd sub/, "you can only give one arg");

eval { with_params([1, 2]); };
like($@, qr/too many arguments/, "error propagated up from P::V");
