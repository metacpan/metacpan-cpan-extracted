use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Local::Dummy1; use Test::Requires 'Class::Tiny' };

note 'Local::Bleh';
{
	package Local::Bleh;
	use Sub::HandlesVia qw( delegations );

	use Class::Tiny {
		nums => sub { [1..2] },   # lazy builder
	};
	delegations(
		attribute    => 'nums',
		handles_via  => 'Array',
		handles      => {
			splice_nums     => 'splice',
			splice_nums_tap => 'splice...',
			first_num       => [ 'get', 0 ],
		},
	);
}

my $bleh = Local::Bleh->new;
my @r = $bleh->splice_nums(0, 2, 3..5);
is_deeply($bleh->nums, [3..5], 'delegated method worked');
is_deeply(\@r, [1..2], '... and returned correct value');
is($bleh->first_num, 3, 'curried delegated method worked');

$bleh = Local::Bleh->new;
@r = $bleh->splice_nums_tap(0, 2, 3..5);
is_deeply($bleh->nums, [3..5], 'delegated method with chaining worked');
is_deeply(\@r, [$bleh], '... and returned correct value');

done_testing;
