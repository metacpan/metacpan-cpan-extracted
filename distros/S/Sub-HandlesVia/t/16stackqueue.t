use 5.008;
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{ package Local::Dummy1; use Test::Requires 'Moo' };

{
	package Local::Stack;
	use Moo;
	use Sub::HandlesVia;
	use Sub::HandlesVia::HandlerLibrary::Array;

	has items => (
		is           => 'bare',
		lazy         => 1,
		coerce       => 1,
		builder      => sub { [] },
		handles_via  => 'Array',
		handles      => HandleStack,
	);
}

my $stack = Local::Stack->new();
ok( $stack->items_is_empty );
$stack->items_push( 11 .. 15 );
ok( ! $stack->items_is_empty );
is( $stack->items_size, 5 );
is( $stack->items_peek, 15 );
is( $stack->items_pop, 15 );
is( $stack->items_pop, 14 );
is( $stack->items_pop, 13 );
is( $stack->items_pop, 12 );
is( $stack->items_pop, 11 );
ok( $stack->items_is_empty );
is( $stack->items_size, 0 );

{
	package Local::Queue;
	use Moo;
	use Sub::HandlesVia;
	use Sub::HandlesVia::HandlerLibrary::Array;

	has items => (
		is           => 'bare',
		lazy         => 1,
		coerce       => 1,
		builder      => sub { [] },
		handles_via  => 'Array',
		handles      => [ HandleQueue, { all_items => 'all' } ],
	);
}

my $q = Local::Queue->new();
ok( $q->items_is_empty );
$q->items_enqueue( 11 .. 15 );
ok( ! $q->items_is_empty );
is( $q->items_size, 5 );
is( $q->items_peek, 11 );
is( $q->items_dequeue, 11 );
is( $q->items_dequeue, 12 );
is( $q->items_dequeue, 13 );
is_deeply( [ $q->all_items ], [ 14, 15 ] );
is( $q->items_dequeue, 14 );
is( $q->items_dequeue, 15 );
ok( $q->items_is_empty );
is( $q->items_size, 0 );

done_testing;
