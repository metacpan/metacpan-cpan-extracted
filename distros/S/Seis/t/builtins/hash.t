use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is(compile('hash().WHAT.gist'), '(Hash)');

done_testing;

