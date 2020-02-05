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
		handles     => [qw/ apply /],
	);
}

my $collection = Local::Class->new(
	collection => [qw/ 1 2 3 4 /],
);

my @r = $collection->apply(sub { $_ *= 2; 1 });
is_deeply(\@r, [2,4,6,8]);
is_deeply($collection->collection, [1,2,3,4]);
done_testing;
