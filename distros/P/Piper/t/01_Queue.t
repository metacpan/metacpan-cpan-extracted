#!/usr/bin/env perl
#####################################################################
## AUTHOR: Mary Ehlers, regina.verbae@gmail.com
## ABSTRACT: Test the Piper::Queue module/role
#####################################################################

use v5.10;
use strict;
use warnings;

use Test::Most;

my $APP = $ENV{PIPER_QUEUE_CLASS} // 'Piper::Queue';

eval {
    eval "require $APP";
    $APP->import;
};

if ($@) {
    die "Could not import $APP: $@";
}

#####################################################################

my $QUEUE = $APP->new();

# Enqueue tested implicitly, since we can't make assumptions
#   about internal structures or any serialize/thaw behaviors

my %TEST = (
    'simple scalars' => {
        data => [ 1..5 ],
    },
    'complex data structures' => {
        data => [
            { hashref => { arrayref => [], scalar => 'scalar' } },
            [qw(mix the main structure types)],
            [ { hashref2 => { arrayref2 => [], scalar2 => 'scalar2' } } ],
            { scalar3 => 'scalar3',
                hashref3 => { arrayref3 => [ hashref4 => { scalar4 => 'scalar4' } ] }
            },
            [ ], #empty!
            { }, #empty!
        ],
    },
);

my $obj_num = 0;
$TEST{'blessed objects'} = {
    data => [
        map {
            my $struct = $_;
            $obj_num++;
            bless $struct, "BLESSED::OBJECT$obj_num"
        } @{$TEST{'complex data structures'}{data}}
    ],
    extra => sub {
        my ($got, $exp, $message) = @_;
        cmp_deeply(
            $got,
            (ref $exp eq 'ARRAY'
                ? [ map { isa(ref $_) } @$exp ]
                : isa(ref $exp)
            ),
            "$message (objects maintained blessing)"
        );
    },
};

for my $test (keys %TEST) {
    subtest "$APP - $test" => sub {
        my @items = @{$TEST{$test}{data}};
        my @top = @items[0..2];

        is($QUEUE->ready, 0, 'ready - before enqueue');
        
        $QUEUE->enqueue(@items);

        is($QUEUE->ready, @items, 'ready - after enqueue');

        my $got = [ $QUEUE->dequeue(2) ];
        my $exp = [ splice @items, 0, 2 ];

        is_deeply(
            $got,
            $exp,
            'dequeue multiple'
        );

        if (exists $TEST{$test}{extra}) {
            $TEST{$test}{extra}->($got, $exp, 'dequeue multiple');
        }

        is($QUEUE->ready, @items, 'ready - after dequeue');

        $got = [ $QUEUE->dequeue ];
        $exp = [ shift @items ];

        is_deeply(
            $got,
            $exp,
            'dequeue default - wantarray'
        );

        if (exists $TEST{$test}{extra}) {
            $TEST{$test}{extra}->($got, $exp, 'dequeue default - wantarray');
        }

        $got = $QUEUE->dequeue;
        $exp = shift @items;

        is_deeply(
            $got,
            $exp,
            'dequeue default - no wantarray'
        );

        if (exists $TEST{$test}{extra}) {
            $TEST{$test}{extra}->($got, $exp, 'dequeue default - no wantarray');
        }

        $QUEUE->requeue(@top);

        is($QUEUE->ready, @items + @top, 'ready - after requeue');

        $got = [ $QUEUE->dequeue(scalar @top) ];
        $exp = \@top;

        is_deeply(
            $got,
            $exp,
            'requeue'
        );

        if (exists $TEST{$test}{extra}) {
            $TEST{$test}{extra}->($got, $exp, 'requeue');
        }

        $got = [ $QUEUE->dequeue( scalar @items + 3 ) ];
        $exp = [ @items ];

        is_deeply(
            $got,
            $exp,
            'dequeue - requested greater than ready'
        );

        if (exists $TEST{$test}{extra}) {
            $TEST{$test}{extra}->($got, $exp, 'dequeue - requested greater than ready');
        }

        is($QUEUE->ready, 0, 'ready - empty');

        is_deeply(
            [ $QUEUE->dequeue ],
            [ ],
            'dequeue - empty'
        );
    };
}

#####################################################################

done_testing();
