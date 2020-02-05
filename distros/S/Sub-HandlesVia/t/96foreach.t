use strict;
use warnings;
use Test::More;
{ package Local::Dummy; use Test::Requires { 'Moo' => '1.006' } };

{
	package Local::Class;
	use Moo;
	use Sub::HandlesVia;
	has collection => (
		is          => 'ro',
		handles_via => 'Array',
		handles     => [qw/ for_each for_each_pair /],
	);
}

my $collection = Local::Class->new(
	collection => [qw/ 1 2 3 4 5 6 /],
);

my @r = ();

is_deeply(
	$collection->for_each(sub {
		push @r, [@_];
	}),
	$collection,
);

is_deeply(
	\@r,
	[[1,0], [2,1], [3,2], [4,3], [5,4], [6,5]],
);

@r = ();

is_deeply(
	$collection->for_each_pair(sub {
		push @r, [@_];
	}),
	$collection,
);

is_deeply(
	\@r,
	[[1,2], [3,4], [5,6]],
);

{
	package Local::Class2;
	use Moo;
	use Sub::HandlesVia;
	has collection => (
		is          => 'ro',
		handles_via => 'Hash',
		handles     => [qw/ for_each_pair for_each_key for_each_value /],
	);
}

$collection = Local::Class2->new(collection => {foo => 1, bar => 2});

@r = ();

is_deeply(
	$collection->for_each_pair(sub {
		push @r, join "|", @_;
	}),
	$collection,
);

is_deeply(
	[sort @r],
	["bar|2", "foo|1"],
);

@r = ();

is_deeply(
	$collection->for_each_key(sub {
		push @r, join "|", @_;
	}),
	$collection,
);

is_deeply(
	[sort @r],
	["bar", "foo"],
);

@r = ();

is_deeply(
	$collection->for_each_value(sub {
		push @r, join "|", @_;
	}),
	$collection,
);

is_deeply(
	[sort @r],
	[1, 2],
);

done_testing;
