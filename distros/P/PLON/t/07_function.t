use strict;
use warnings;
use utf8;
use Test::More;
use PLON;

is encode_plon([]), '[]';
is_deeply decode_pson('[]'), [];

done_testing;

