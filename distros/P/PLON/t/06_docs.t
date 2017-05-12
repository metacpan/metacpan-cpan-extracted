use strict;
use warnings;
use utf8;
use Test::More;
use PLON;

is(PLON->new->ascii(1)->encode([chr 0x10401]) => q!["\x{10401}",]!);

done_testing;

