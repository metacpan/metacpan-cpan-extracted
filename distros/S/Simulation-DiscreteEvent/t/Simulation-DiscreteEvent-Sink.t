use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;
use ok 'Simulation::DiscreteEvent';

my $model = Simulation::DiscreteEvent->new();
my $sink = $model->add(
    'Simulation::DiscreteEvent::Sink',
);
    
isa_ok $sink, 'Simulation::DiscreteEvent::Sink', '$sink';

my $events = [
    [ 1, 'start' ],
    [ 2, 'stop'  ],
    [ 4, 'start' ],
    [ 5, 'stop'  ],
    [ 7, 'oops'  ],
];
for (@$events) {
    $model->schedule($_->[0], $sink, $_->[1], $_->[2]);
}

$model->run;

is $model->time, 7, "stopped at 7";
is_deeply [ $sink->get_all_events ], $events, "all events are recorded";
is $sink->get_number_of('oops'), 1, 'oops';



$model = Simulation::DiscreteEvent->new();
$sink = $model->add(
    'Simulation::DiscreteEvent::Sink',
    allowed_events => [ 'start', 'stop' ],
);
    
isa_ok $sink, 'Simulation::DiscreteEvent::Sink', '$sink';
for (@$events) {
    $model->schedule($_->[0], $sink, $_->[1], $_->[2]);
}

dies_ok { $model->run } "run has died";
is $sink->get_number_of('start'), 2, "two starts";

