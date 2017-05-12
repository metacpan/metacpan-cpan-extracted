use Test::More tests => 6;
use Pointy::Counter;

my $x = counter 1;

is($x->value, 1);
$x--;
is($x->value, 2);

$x->value = 4;
is($x->value, 4);
$x--;
is($x->value, 5);

$x->value(7);
is($x->value, 7);
$x--;
is($x->value, 8);
