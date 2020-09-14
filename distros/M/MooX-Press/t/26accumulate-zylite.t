use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Zydeco::Lite;

app 'MyApp' => sub {
	class 'Foo';
};

app 'MyApp' => sub {
	class 'Bar' => sub {
		has 'foo' => ( type => 'Foo' );
	};
};

my $foo = MyApp->new_foo;
my $bar = MyApp->new_bar( foo => $foo );

isnt(
	exception { $bar->foo(undef) },
	undef,
);

done_testing;
