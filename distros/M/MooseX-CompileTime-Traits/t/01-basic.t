use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Bar;
use Baz;
use Faz traits => [Bar => {bar => 1}];
use Foo traits => [Bar => {bar => 2}];
use Flarg traits => ['Faz', Baz => {baz => 2}];
is(Foo->new->bar(), 4, 'Got 4');
my $flarg = Flarg->new();
is($flarg->bar(), 3, 'Got 3');
is($flarg->baz(), 5, 'Got 5');

done_testing();
