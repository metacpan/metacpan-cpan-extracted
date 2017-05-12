#!perl -T
use strict;
use warnings;

use Test::More tests => 5;

BEGIN { use_ok('Sub::MicroSig'); }
use Params::Validate::Micro qw(micro_validate);

sub with_params :Sig($foo bar @baz) {
  return @_;
}

is_deeply(
  with_params({ foo => 20, bar => [], baz => [] }),
  { foo => 20, bar => [], baz => [] },
  "named params to sig, aref for untyped"
);

is_deeply(
  with_params({ foo => 20, bar => {}, baz => [] }),
  { foo => 20, bar => {}, baz => [] },
  "named params to sig, href for untyped"
);

is_deeply(
  with_params({ foo => 20, bar => 2, baz => [] }),
  { foo => 20, bar => 2, baz => [] },
  "named params to sig, scalar for untyped"
);

is_deeply(
  with_params([ 20, 2, [] ]),
  { foo => 20, bar => 2, baz => [] },
  "positional params to sig, aref for untyped"
);

