use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile('my $v-a-r = 3; $v-a-r'), 3;

done_testing;

