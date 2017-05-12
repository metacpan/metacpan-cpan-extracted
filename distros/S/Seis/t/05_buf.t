use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is_deeply(compile('Buf.new'), Buf->new);

done_testing;

