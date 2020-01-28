use strict;
use warnings;
use Test::More;
{ package Local::Dummy; use Test::Requires 'Moo' };

{
	package Local::Class;
	use Moo;
	use Sub::HandlesVia;
	has collection => (
		is          => 'ro',
		handles_via => 'Array',
		handles     => [qw/ pick_random /],
	);
}

my $collection = Local::Class->new(
	collection => [qw/ 1 2 3 4 5 6 7 8 /],
);

note(
	explain scalar $collection->pick_random(3),
);

note(
	explain scalar $collection->pick_random(3),
);

note(
	explain scalar $collection->pick_random(3),
);

note(
	explain scalar $collection->pick_random(1),
);

note(
	explain scalar $collection->pick_random(30),
);

note(
	explain scalar $collection->pick_random(-5),
);

note(
	explain scalar $collection->pick_random(),
);

ok 1;

done_testing;