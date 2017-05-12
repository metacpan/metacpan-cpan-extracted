use strict;
use warnings;
use utf8;
use Test::More;
use t::Util;

is compile('my $i=0; for 1..10 { $i += $_ }; $i'), 55;

done_testing;

