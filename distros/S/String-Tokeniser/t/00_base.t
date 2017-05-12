# -*- cperl -*-
use Test::More tests => 5;

use_ok("String::Tokeniser");

ok($testtwo = String::Tokeniser->new("The quick brown foo_bar"));

is(join(":",@{$testtwo->{LIST}}),"The: :quick: :brown: :foo_bar:");

# Now check for weave-style tokenising:
ok($testfour = String::Tokeniser->new("The quick brown foo_bar",-1));

is(join(":",@{$testfour->{LIST}}),"The: :quick: :brown: :foo:_:bar:");

