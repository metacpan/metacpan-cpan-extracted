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
		handles     => [qw/ head tail /],
	);
}

my $collection = Local::Class->new(
	collection => [qw/ a b c d e f /],
);

# head
is_deeply [$collection->head(0)], [], 'head(0)';
is_deeply [$collection->head(3)], [qw{a b c}], 'head(3)';
is_deeply [$collection->head(30)], [qw{a b c d e f}], 'head(30)';
is_deeply [$collection->head(-2)], [qw{a b c d}], 'head(-2)'
	or diag explain[ $collection->head(-2) ];
is_deeply [$collection->head(-30)], [], 'head(-30)'
	or diag explain[ $collection->head(-30) ];

# tail
is_deeply [$collection->tail(0)], [], 'tail(0)';
is_deeply [$collection->tail(3)], [qw{d e f}], 'tail(3)';
is_deeply [$collection->tail(30)], [qw{a b c d e f}], 'tail(30)';
is_deeply [$collection->tail(-2)], [qw{c d e f}], 'tail(-2)';
is_deeply [$collection->tail(-30)], [], 'tail(-30)';

done_testing;
