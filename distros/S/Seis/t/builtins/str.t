use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is(compile('"Hoge".fc'), 'hoge');
is(compile('"a".ord'), 97);

done_testing;

