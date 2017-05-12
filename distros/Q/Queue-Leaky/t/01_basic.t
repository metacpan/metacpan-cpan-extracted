use strict;
use Test::More tests => 24;
use Queue::Leaky;

{
    my $queue = Queue::Leaky->new;

    ok( $queue, "queue ok" );
    isa_ok( $queue, "Queue::Leaky", "queue class ok" );

    my $message = "Hello!";

    ok( $queue->insert($message) );
    ok( $queue->next );
    is( $queue->fetch, "Hello!" );
    ok( $queue->clear );
}

{
    my $max = 3;
    my $queue = Queue::Leaky->new(
        max_items => $max,
    );

    for my $count (1 .. $max) {
        ok( $queue->insert($count) );
    }
    ok( !$queue->insert("I'm not there") );

    for my $count (1 .. $max) {
        ok( $queue->next );
        is( $queue->fetch, $count );
    }
    ok( !$queue->next );

    is( $queue->state_get($queue->queue), 0 );
}

{
    my $max = 3;
    my $queue = Queue::Leaky->new;

    for my $count (1 .. $max) {
        ok( $queue->insert($count) );
    }

    is( $queue->state_get($queue->queue), 3 );

    ok( $queue->clear );

    is( $queue->state_get($queue->queue), 0 );
}
