use strict;
use warnings;
use Test::More;
use Test::Fatal;

use MooX::Press (
	prefix => 'MyApp',
	class  => [
		'Foo' => {},
	],
);

use MooX::Press (
	prefix => 'MyApp',
	class  => [
		'Bar' => { has => { foo => { type => 'Foo' } } },
	],
);

my $foo = MyApp->new_foo;
my $bar = MyApp->new_bar(foo => $foo);

isnt(
	exception { $bar->foo(undef) },
	undef,
);

done_testing;
