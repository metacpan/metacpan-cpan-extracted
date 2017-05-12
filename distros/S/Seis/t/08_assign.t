use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile('my ($a,$b,$c)=<a b c>; $a'), 'a';

done_testing;

