use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is(compile('class Point { has $!x; method set_x($x) { $!x=$x }; method get_x() { $!x } }; my $p = Point.new; $p.set_x(3); $p.get_x'), 3);

done_testing;

