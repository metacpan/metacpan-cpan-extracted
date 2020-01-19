use strict;
use warnings;
use Test::More;

package MyApp {
	use MooX::Pression;
	class MyClass {
		method one ( $foo, $bar, @baz ) {
			return [ $self, $class, $foo, $bar, \@baz ];
		}
		method two ( $foo, $bar, %baz ) {
			return [ $self, $class, $foo, $bar, \%baz ];
		}
	}
}

my $obj = MyApp->new_myclass;

is_deeply(
	$obj->one(1 .. 5),
	[ $obj, ref($obj), 1, 2, [3..5] ],
);

is_deeply(
	$obj->two(1, 2, foo => 3, bar => 4),
	[ $obj, ref($obj), 1, 2, { foo => 3, bar => 4 } ],
);

is_deeply(
	$obj->two(1, 2, { foo => 3, bar => 4 }),
	[ $obj, ref($obj), 1, 2, { foo => 3, bar => 4 } ],
);

done_testing;


