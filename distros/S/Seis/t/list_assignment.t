use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile('my @a=<a b c>; @a[20] = "e"; @a[20]'), 'e';

done_testing;

