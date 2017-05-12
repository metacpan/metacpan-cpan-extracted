use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is(compile('my @a=4,2,3; shift(@a)'), 4);
is(compile('my @a=4,2,3; pop(@a)'), 3);

done_testing;

