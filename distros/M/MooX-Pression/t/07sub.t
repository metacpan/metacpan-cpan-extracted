use strict;
use warnings;
use Test::More;

package MyApp {
	use MooX::Pression;
	
	class Foo {
		has foo;
		
		# Creates a sub in MyApp, not in MyApp::Foo
		sub get_foo {
			# __PACKAGE__ refers to MyApp
			state $instance = __PACKAGE__->new_foo;
			return $instance;
		}
	}
}

my $f1 = MyApp->get_foo;
$f1->foo(42);

my $f2 = MyApp->get_foo;
is($f2->foo, 42);

done_testing;
