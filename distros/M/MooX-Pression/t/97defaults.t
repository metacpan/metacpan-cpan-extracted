use strict;
use warnings;
use Test::More;

package MyApp {
	use MooX::Pression;
	
	class Foo {
		has  foo = 666;
		has  bar(type => Num) = 999;
		has {'baz'} = 42;
	}
}

my $foo = MyApp->new_foo;
is($foo->foo, 666);
is($foo->bar, 999);
is($foo->baz, 42);

done_testing;
