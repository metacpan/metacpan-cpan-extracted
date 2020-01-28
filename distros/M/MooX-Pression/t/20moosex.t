use strict;
use warnings;
use Test::More;
use Test::Fatal;
{
	package Local::Dummy1;
	use Test::Requires 'Moose';
	use Test::Requires 'MooseX::Aliases';
	use Test::Requires 'MooseX::StrictConstructor';
}

my $var;
package Local::Test {
	BEGIN { $INC{'Local/Test.pm'} = __FILE__ };
	sub import { $var = caller };
}

package MyApp {
	use MooX::Pression;
	class Foo {
		toolkit Moose (Aliases, StrictConstructor, ::Local::Test);
		has this ( type => 'Str', alias => 'that' );
	}
}

my $foo1 = MyApp->new_foo(this => 'xyz');
my $foo2 = MyApp->new_foo(that => 'xyz');

is_deeply($foo1, $foo2);

isnt(
	exception { MyApp->new_foo(the_other => 'xyz') },
	undef,
);

is(
	$var,
	ref($foo1),
);

done_testing;
