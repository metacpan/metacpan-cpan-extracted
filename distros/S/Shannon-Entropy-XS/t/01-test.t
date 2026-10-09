use Test::More;
 
use strict;
use warnings;
use Shannon::Entropy::XS qw/entropy/;
is(entropy(''), 0);
is(entropy('0'), 0);
is(sprintf('%.3f', entropy('1223334444')) + 0, 1.846);
is(entropy('0123456789abcdef'), 4),
is(sprintf('%.3f', entropy('abcdefghijklmnopqrst123456789!@£[]"')) + 0, 5.170),

my %h = (k => '1223334444');
my @a = ('1223334444', 'ab');
is(sprintf('%.3f', entropy($h{k})) + 0, 1.846);
is(sprintf('%.3f', entropy($a[0])) + 0, 1.846);

sub two { return ('ab', 'cd') }
my @r = (7, eval { entropy(two()) }, 8);
is("@r", '7 8', 'a list argument leaves nothing behind');
like($@, qr/Usage/, 'and is refused');
@r = (7, eval { entropy(@a) }, 8);
is("@r", '7 8');
@r = (7, entropy(substr('1223334444', 0)), 8);
is(sprintf('%d %.3f %d', @r), '7 1.846 8');

done_testing();
