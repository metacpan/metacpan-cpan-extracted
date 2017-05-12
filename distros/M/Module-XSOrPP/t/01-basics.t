#!perl

use 5.010;
use strict;
use warnings;

use Module::XSOrPP qw(is_xs is_pp xs_or_pp);
use Test::More 0.98;

ok( is_xs("List::Util"));
ok(!is_pp("List::Util"));
is(xs_or_pp("List::Util"), "xs");

ok(!is_xs("Test::More"));
ok( is_pp("Test::More"));
is(xs_or_pp("Test::More"), "pp");

ok( is_xs("List::MoreUtils"));
ok( is_pp("List::MoreUtils"));
is(xs_or_pp("List::MoreUtils"), "xs_or_pp");

ok(!defined(is_xs("FooBar")));

# xs from list
ok( is_xs("Scalar::Util"));
ok(!is_pp("Scalar::Util"));
is(xs_or_pp("Scalar::Util"), "xs");

done_testing;
