use strict;
use warnings;

use Test::More qw(no_plan);
use Simulation::DiscreteEvent;

{
    package Test::DE::Recorder;
    use Moose;
    BEGIN { 
        extends 'Simulation::DiscreteEvent::Server';
    }
    with 'Simulation::DiscreteEvent::Recorder';
    sub handler1 : Event(first)  { 1 }
    sub handler2 : Event(second) { 1 }
    sub handler3 : Event(third)  { 1 }
}

my $model = Simulation::DiscreteEvent->new;

# add servers to model
my $server1 = $model->add('Test::DE::Recorder');
my $server2 = $model->add('Test::DE::Recorder');

# schedule some events for every server
my @events = (
    [ 0, $server1, 'first'  ],
    [ 0, $server1, 'second' ],
    [ 1, $server1, 'third'  ],
    [ 2, $server2, 'third'  ],
    [ 3, $server1, 'second' ],
    [ 4, $server2, 'first'  ],
    [ 5, $server1, 'second' ],
    [ 5, $server2, 'third'  ],
    [ 5, $server1, 'third'  ],
    [ 7, $server2, 'first'  ],
);
for (@events) {
    $model->schedule(@$_);
}

# now run model
$model->run;

# and check collected statistic
my @srv1_ev = map { [ $_->[0], $_->[2] ] } grep { $_->[1] eq $server1 } @events;
my @srv2_ev = map { [ $_->[0], $_->[2] ] } grep { $_->[1] eq $server2 } @events;

is_deeply [ $server1->get_all_events ], \@srv1_ev, "get_all_events for server 1";
is_deeply [ $server2->get_all_events ], \@srv2_ev, "get_all_events for server 2";

is $server1->get_number_of, 0+@srv1_ev, "get_number_of";
is $server2->get_number_of('third'), 2, "get_number_of(third)";

my @srv1_time = map { $_->[0] } @srv1_ev;
is_deeply [ $server1->get_moments_of ], \@srv1_time, "get_moments_of";
is_deeply [ $server2->get_moments_of('first') ], [ 4, 7 ], "get_moments_of(first)";

# intervals between events
my @srv1_int_all = ( 0, 1, 2, 2, 0 );
# intervals between events 'first'
my @srv1_int_first = ();
# intervals between events 'second'
my @srv1_int_second = (3, 2);
is_deeply [ $server1->intervals_between ], \@srv1_int_all, 'intervals_between';
is_deeply [ $server1->intervals_between('first') ], [], 'intervals_between(first)';
is_deeply [ $server1->intervals_between('second') ], \@srv1_int_second, 'intervals_between(second)';

