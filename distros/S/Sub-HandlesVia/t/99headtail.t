use strict;
use warnings;
use Test::More;
use Test::Fatal;
{ package Local::Dummy; use Test::Requires { 'Moo' => '1.006' } };

{
	package Local::Class;
	use Moo;
	use Sub::HandlesVia;
	has collection => (
		is          => 'ro',
		handles_via => 'Array',
		handles     => {
			front => 'head',
			back  => 'tail',
		},
	);
}

my $collection = Local::Class->new(
	collection => [qw/ a b c d e f /],
);

# head
is_deeply [$collection->front(0)], [], 'head(0)';
is_deeply [$collection->front(3)], [qw{a b c}], 'head(3)';
is_deeply [$collection->front(30)], [qw{a b c d e f}], 'head(30)';
is_deeply [$collection->front(-2)], [qw{a b c d}], 'head(-2)'
	or diag explain[ $collection->front(-2) ];
is_deeply [$collection->front(-30)], [], 'head(-30)'
	or diag explain[ $collection->front(-30) ];

# tail
is_deeply [$collection->back(0)], [], 'tail(0)';
is_deeply [$collection->back(3)], [qw{d e f}], 'tail(3)';
is_deeply [$collection->back(30)], [qw{a b c d e f}], 'tail(30)';
is_deeply [$collection->back(-2)], [qw{c d e f}], 'tail(-2)';
is_deeply [$collection->back(-30)], [], 'tail(-30)';

# exception
like(
	exception { $collection->front(3, 4, 5) },
	qr/Wrong number of parameters; got 4; expected 2 at front=Array:head/,
	'Correct exception',
);

done_testing;
