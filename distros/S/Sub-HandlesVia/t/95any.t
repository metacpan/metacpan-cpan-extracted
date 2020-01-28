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
		handles     => [qw/ any /],
	);
}

my $collection = Local::Class->new(
	collection => [qw/ 1 2 3 4 /],
);

ok(
	$collection->any(sub { $_==3 }),
);

ok(
	!$collection->any(sub { $_==5 }),
);

done_testing;
