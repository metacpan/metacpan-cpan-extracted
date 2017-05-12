use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile('[max] 4,2,3'), 4;
is compile('[+] 1,2,3') => 6;
is compile('[*] 4,2,3') => 24;
is compile('[min] 4,2,3') => 2;

done_testing;

