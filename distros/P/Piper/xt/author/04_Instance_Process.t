#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Instance module on single process
#####################################################################

use v5.10;
use strict;
use warnings;

use Test::Most;
use Test::Memory::Cycle;

my $APP = "Piper::Instance (process)";

use Piper::Process;

#####################################################################

# Test args
{
    subtest "$APP - args" => sub {
        my $ARG = Piper::Process->new(argy => {
            batch_size => 2,
            handler => sub {
                my ($instance, $batch, @args) = @_;
                if ($args[0] eq 'arg') {
                    $instance->emit(@$batch);
                }
            },
        })->init('arg');

        is($ARG->args->[0], 'arg', 'stored ok');

        $ARG->enqueue(1..2);
        $ARG->process_batch;
        is_deeply(
            [ $ARG->dequeue(2) ],
            [ 1..2 ],
            'passthrough to handler ok'
        );
    };
}

my $TEST = Piper::Process->new(half => {
    batch_size => 2,
    # Non-explicitly testing that allow $_ closure works
    allow => sub { $_ % 2 == 0 },
    handler => sub {
        my ($instance, $batch, @args) = @_;
        $instance->emit(map { int( $_ / 2 ) } @$batch);
    },
})->init();

# Test path
{
    subtest "$APP - path" => sub {
        is($TEST->path, $TEST->label, 'stringifies to label');
    };
}

# Test parent predicate
{
    subtest "$APP - parent predicate" => sub {
        ok(!$TEST->has_parent, 'no parent');
    };
}

# Test batch_size
{
    subtest "$APP - batch_size" => sub {
        is($TEST->batch_size, 2, 'ok');
    };
}

# Test queueing
{
    subtest "$APP - queueing" => sub {
        ok(!$TEST->pending, 'not yet pending');
        ok(!$TEST->ready, 'not yet ready');
        is($TEST->pressure, 0, 'no pressure');

        my @data = (1..3);
        $TEST->enqueue(map { $_ * 2 } @data);

        is($TEST->pending, 3, 'pending items');
        ok(!$TEST->ready, 'still not ready');
        is($TEST->pressure, 150, 'positive pressure');
    };
}

# Test process_batch
{
    subtest "$APP - process_batch" => sub {
        $TEST->process_batch;

        is($TEST->pending, 1, 'removed from pending queue');
        is($TEST->ready, 2, 'items processed successfully');

        $TEST->process_batch;

        is($TEST->pending, 0, 'removed un-full batch from pending queue');
        is($TEST->ready, 3, 'un-full batch processed successfully');
    };
}

# Test dequeue
{
    subtest "$APP - dequeue" => sub {
        is_deeply(
            [ $TEST->dequeue(2) ],
            [ 1..2 ],
            'dequeue multiple'
        );

        is($TEST->dequeue, 3, 'dequeue single');

        is_deeply(
            [ $TEST->dequeue(2) ],
            [],
            'dequeue empty'
        );
    };
}

# Test exhaustion
{
    subtest "$APP - exhaustion" => sub {
        ok($TEST->is_exhausted, 'empty - is_exhausted');
        ok(!$TEST->isnt_exhausted, 'empty - isnt_exhausted');

        $TEST->enqueue(3);

        ok(!$TEST->is_exhausted, 'queued - is_exhausted');
        ok($TEST->isnt_exhausted, 'queued - isnt_exhausted');

        while ($TEST->isnt_exhausted) {
            $TEST->dequeue;
        }

        ok($TEST->is_exhausted, 'emptied - is_exhausted');
        ok(!$TEST->isnt_exhausted, 'emptied - isnt_exhausted');
    };
}

# Test allow
{
    subtest "$APP - allow" => sub {
        # Odd number skipped
        $TEST->enqueue(1..5);
        
        is($TEST->pending, 2, 'allowed items pending');
        is($TEST->ready, 3, 'skipped items ready');
        is_deeply(
            [ $TEST->dequeue(5) ],
            [ 1, 3, 5 ],
            'allow succeeded'
        );

        $TEST->process_batch;
        is($TEST->ready, 2, 'allowed items processed');
        is_deeply(
            [ $TEST->dequeue(2) ],
            [ 1, 2 ],
            'allowed items processed correctly'
        );
    };
}

# Test disabling
{
    subtest "$APP - disabling" => sub {
        $TEST->enabled(0);
        is($TEST->enabled, 0, 'disabled');

        $TEST->enqueue(1..3);
        is($TEST->pending, 0, 'nothing pending in disabled process');
        is($TEST->ready, 3, 'items skipped disabled process');

        is_deeply(
            [ $TEST->dequeue(3) ],
            [ 1..3 ],
            'skipped items dequeued unchanged'
        );

        $TEST->enabled(1);
    };
}

# Test find_segment
{
    subtest "$APP - find_segment" => sub {
        is($TEST->find_segment('half'), $TEST->label, 'ok');
        is($TEST->find_segment('bad'), undef, 'bad label not found');
    };
}

# Test emit
{
    subtest "$APP - emit" => sub {
        $TEST->emit(4..6);
        is_deeply(
            [ $TEST->dequeue(3) ],
            [ 4..6 ],
            'fake emit - ok'
        );

        my $EMITTER = Piper::Process->new(double => {
            batch_size => 2,
            handler => sub {
                my ($instance, $batch, @args) = @_;
                $instance->emit(map { $_ * 2 } @$batch);
            },
        })->init();

        $EMITTER->enqueue(1..3);
        $EMITTER->process_batch;
        
        is_deeply(
            [ $EMITTER->dequeue(2) ],
            [ 2, 4 ],
            'full batch - emit ok'
        );

        $EMITTER->process_batch;

        is_deeply(
            [ $EMITTER->dequeue(2) ],
            [ 6 ],
            'partial batch - emit ok'
        );
    };
}

# Test recycle
{
    subtest "$APP - recycle" => sub {
        $TEST->recycle(2);
        is($TEST->pending, 1, 'fake recycle - ok');
        $TEST->process_batch;
        $TEST->dequeue;

        my $RECYCLER = Piper::Process->new(mod_power_2 => {
            batch_size => 3,
            # Non-explicitly testing that allow $_ closure still allows use of $_[0]
            allow => sub { $_[0] % 2 == 0 },
            handler => sub {
                my ($instance, $batch, @args) = @_;
                my @things = map { int( $_ / 2 ) } @$batch;
                for my $thing (@things) {
                    if ($thing > 0 and $thing % 2 == 0) {
                        $instance->recycle($thing);
                    }
                    else {
                        $instance->emit($thing);
                    }
                }
            },
        })->init();

        $RECYCLER->enqueue(2..4);
        $RECYCLER->process_batch;
        is($RECYCLER->pending, 1, 'recycle successful');
    };
}

# Test eject
{
    subtest "$APP - eject" => sub {
        $TEST->eject(2);
        is_deeply(
            [ $TEST->dequeue ],
            [ 2 ],
            'ok'
        );
    };
}

# Test inject
{
    subtest "$APP - inject" => sub {
        $TEST->inject(2,4,6);
        is($TEST->pending, 3, 'ok');
    };
}

# Test injectAt
{
    subtest "$APP - injectAt" => sub {
        $TEST->injectAt('half', 8, 10);
        is($TEST->pending, 5, 'ok');

        throws_ok {
            $TEST->injectAt('bad', 1..4)
        } qr/Could not find bad to injectAt/, 'no inject with bad label';
    };
}

# Test injectAfter
{
    subtest "$APP - injectAfter" => sub {
        $TEST->injectAfter('half', 1..4);
        is($TEST->ready, 4, 'ok');

        throws_ok {
            $TEST->injectAfter('bad', 1..4)
        } qr/Could not find bad to injectAfter/, 'no injectAfter with bad label';
    };
}

# Test memory leaks
{
	subtest "$APP - memory" => sub {
		memory_cycle_ok($TEST, 'no memory leaks');
	};
}

#####################################################################

done_testing();
