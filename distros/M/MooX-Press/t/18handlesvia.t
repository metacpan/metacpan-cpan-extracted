use strict;
use warnings;
use Test::More;
use Test::Requires 'Sub::HandlesVia';

{
	package MyApp;
	use MooX::Press (
		'class:Kitchen' => {
			has => {
				'food' => {
					is          => 'ro',
					type        => 'ArrayRef[Str]',
					builder     => sub { [] },
					handles_via => 'Array',
					handles     => {
						add_food     => 'push',
						remove_food  => 'pop',
						first_food   => [ 'get', 0 ],
					},
				},
			},
		},
	);
}

my $kitchen = MyApp->new_kitchen;

$kitchen->add_food('Bacon', 'Eggs', 'Beans');

is_deeply(
	$kitchen->food,
	[qw/ Bacon Eggs Beans /],
);

is(
	$kitchen->remove_food,
	'Beans',
);

is(
	$kitchen->first_food,
	'Bacon',
);

done_testing;
