use strict;
use warnings;
use Test::More;
use Test::Fatal;
use MooX::Pression prefix => 'Local';

class Foo;

class Bar {
	method bar (
		# Integer or complex thingy
		Int | ArrayRef[Str|HashRef[~Int]]
		$baz     # ... called $baz
		= 999    # defaults to 999
	) {
		1;
	}
}

my $bar = Local->new_bar;

ok( $bar->bar( 1 ) );

ok( $bar->bar( [qw/ x y z /] ) );

ok( $bar->bar( [qw/ x y z /, {}] ) );

ok( $bar->bar( [qw/ x y z /, { quux => 'quuux' }] ) );

ok( $bar->bar( [qw/ x y z /, { quux => \1 }] ) );

isnt( 
	exception { $bar->bar( [qw/ x y z /, { quux => 42 }] ) },
	undef,
);

done_testing;
