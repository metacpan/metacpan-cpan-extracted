use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

ok compile('2.is-prime');
ok !compile('4.is-prime');

done_testing;

