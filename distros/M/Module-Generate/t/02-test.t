use Test::More;

use lib 't/lib';
use Foo;

my $foo = Foo->new;

is($foo->one, 'abc');
is($foo->name(10, 10), 20);

use Foo::Bar;

my $bar = Foo::Bar->new;

is($bar->one, 'abc');
is($bar->name(10, 10), 20);
is($bar->different(10, 10), 20);

done_testing();
