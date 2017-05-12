use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile('"a\c[COMBINING DIAERESIS]"'), "a\x{0308}";

done_testing;

