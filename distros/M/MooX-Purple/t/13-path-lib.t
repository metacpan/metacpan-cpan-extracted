use Test::More;
use lib 't/lib';

use Day::Night;
use Day::Night::Day;

my $night = Day::Night->new();
is($night->nine, 'crazy');

my $night = Day::Night::Day->new();
is($night->nine, 'crazy');

done_testing();
