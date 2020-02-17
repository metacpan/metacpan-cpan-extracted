use strict;
use warnings;
use Test::More;

use MooX::Press (
	factory_package => undef,
	role => [
		'::FooRole' => { requires => ['foo', {}] }
	]
);

ok !eval q{
	package Local::MyClass1;
	use Moo;
	with "FooRole";
	1;
};

ok eval q{
	package Local::MyClass2;
	use Moo;
	with "FooRole";
	sub foo { 42 }
	1;
};

done_testing;

