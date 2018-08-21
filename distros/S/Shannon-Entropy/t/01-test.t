use Test::More;

use strict;
use warnings;
use Shannon::Entropy qw/entropy/;

is(entropy(''), 0);
is(entropy('0'), 0);
is(sprintf('%.16f', entropy('1223334444')) + 0, 1.8464393446710154);
is(entropy('0123456789abcdef'), 4),
is(sprintf('%.14f', entropy('abcdefghijklmnopqrst123456789!@£[]"')) + 0, 5.16992500144231),

done_testing();
