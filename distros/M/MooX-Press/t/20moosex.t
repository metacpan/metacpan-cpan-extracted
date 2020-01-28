use strict;
use warnings;
use Test::More;
{
	package Local::Dummy1;
	use Test::Requires 'Moose';
	use Test::Requires 'MooseX::Aliases';
}

{
	package MyApp;
	use MooX::Press (
		toolkit => 'Moose',
		import  => [ 'MooseX::Aliases' ],
		class   => {
			'Foo' => {
				has => {
					this => { type => 'Str', alias => 'that' },
				},
			},
		},
	);
}

my $foo1 = MyApp->new_foo(this => 'xyz');
my $foo2 = MyApp->new_foo(that => 'xyz');

is_deeply($foo1, $foo2);

done_testing;
