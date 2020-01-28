use strict;
use warnings;
use Test::More;

{
	package MyApp;
	use MooX::Press (
		class => [
			Foo => {
				has => ['@list'],
				overload => {
					'@{}' => sub { shift->list },
				},
			},
		],
	);
}


my $foo = MyApp->new_foo(list => [42]);

is_deeply([@$foo], [42]);

done_testing;
