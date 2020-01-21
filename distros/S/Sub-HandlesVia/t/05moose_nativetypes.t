use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Local::Dummy1; use Test::Requires 'Moose' };

use Moose::Util::TypeConstraints;

type 'MyArrayRefOfInt', as 'ArrayRef[Int]';
coerce 'MyArrayRefOfInt',
	from 'ArrayRef[Num]', via { die "COERCION CALLED ON @$_"; [ map int($_), @$_ ] };

note 'Local::Bleh';
{
	package Local::Bleh;
	use Moose;
	use Sub::HandlesVia;

	has nums => (
		is           => 'ro',
		lazy         => 1,
		isa          => 'MyArrayRefOfInt',
		coerce       => 1,
		builder      => '_build_nums',
		handles_via  => 'Array',
		handles      => {
			splice_nums     => 'splice',
			splice_nums_tap => 'splice...',
			first_num       => [ 'get', 0 ],
		},
	);
	sub _build_nums { [1..2] }
}


my $bleh = Local::Bleh->new;
my @r = $bleh->splice_nums(0, 2, 3..5);
is_deeply($bleh->nums, [3..5], 'delegated method worked');
is_deeply(\@r, [1..2], '... and returned correct value');
is($bleh->first_num, 3, 'curried delegated method worked');

{
	local $TODO = 'this is currently broken';
	my $e = exception {
		$bleh->splice_nums(1, 0, "foo");
	};
	like($e, qr/does not pass the type constraint/, 'delegated method checked incoming types');
	is_deeply($bleh->nums, [3..5], '... and kept the value safe');
}

my $ref;
{
	local $TODO = 'this is currently broken';
	$ref = $bleh->nums;
	$bleh->splice_nums(1, 0, '3.111');
	is_deeply($bleh->nums, [3, 3, 4, 5], 'delegated coerced value');
}

my $ref2 = $bleh->nums;
isnt("$ref", "$ref2", '... but sadly needed to build a new arrayref');

$bleh = Local::Bleh->new;
@r = $bleh->splice_nums_tap(0, 2, 3..5);
is_deeply($bleh->nums, [3..5], 'delegated method with chaining worked');
is_deeply(\@r, [$bleh], '... and returned correct value');

done_testing;
