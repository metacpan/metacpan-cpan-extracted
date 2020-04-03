use Test::More;
use lib 't/lib';

use Everyday::Night;
use Everyday::Day::Night::Day;

my $night = Everyday::Night->new();
is($night->nine, 'crazy');

my $night = Everyday::Day::Night::Day->new();
is($night->nine, 'crazy');

done_testing();
