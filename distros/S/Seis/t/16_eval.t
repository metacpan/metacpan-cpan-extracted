use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile(q!my $x=3; eval('$x')!), 3;

done_testing;

