use Test::More;

use lib 't/lib';

use Macro::Simple;
use Macro::Inherit;

my $simple = Macro::Simple->new();

is($simple->one, 'crazy');
is($simple->two, 101);

$simple = Macro::Inherit->new();
is($simple->one, 'crazy');
is($simple->two, 101);

done_testing();
