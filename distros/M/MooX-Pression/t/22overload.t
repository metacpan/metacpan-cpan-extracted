use strict;
use warnings;
use Test::More;
{ package Local::Dummy1; use Test::Requires { 'MooX::Press' => '0.033' } };

package MyApp {
	use MooX::Pression;
	class Foo {
		has list = [];
		overload '@{}' => sub { shift->list };
	}
}


my $foo = MyApp->new_foo(list => [42]);

is_deeply([@$foo], [42]);

done_testing;
