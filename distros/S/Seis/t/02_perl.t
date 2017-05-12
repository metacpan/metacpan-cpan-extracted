use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is(compile('1.perl'), 1);
is(compile('(3.14).perl'), 3.14);
is(compile('"Heh\nhoh".perl'), '"Heh\nhoh"');

done_testing;

