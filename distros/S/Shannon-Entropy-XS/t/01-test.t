use Test::More;
 
use strict;
use warnings;
use Shannon::Entropy::XS qw/entropy/;
is(entropy(''), 0);
is(entropy('0'), 0);
is(sprintf('%.3f', entropy('1223334444')) + 0, 1.846);
is(entropy('0123456789abcdef'), 4),
is(sprintf('%.3f', entropy('abcdefghijklmnopqrst123456789!@£[]"')) + 0, 5.170),
 
done_testing();
