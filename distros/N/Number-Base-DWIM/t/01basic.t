#!/usr/bin/perl

use Test::More tests => 7;

BEGIN {
  use_ok("Number::Base::DWIM") or exit;
}

# We have to call import again, since use_ok calls import from inside
# of an eval, which is documented as being broken in the overload
# docs.

use Number::Base::DWIM;

my $obj = 011;

is($obj . "", "011", "stringification");
is(int($obj), 9, "numification");

is($obj + 1, 10, "addition");
is($obj - 1, 8, "subtraction");
is($obj & 1, 1, "bitwise and");

is($obj . "1", "0111", "concatentation");
