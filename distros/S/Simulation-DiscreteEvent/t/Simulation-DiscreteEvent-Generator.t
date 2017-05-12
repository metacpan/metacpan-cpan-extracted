use strict;
use warnings;

use Test::Most qw(no_plan);
use ok 'Simulation::DiscreteEvent';

my @events;

{
    package Test::DE::Sink;
    use Moose;
    BEGIN { extends 'Simulation::DiscreteEvent::Server' }
    sub message : Event {
        my ($self, $message) = @_;
        push @events, [ $self->model->time, $message ];
    }
}

my $model = Simulation::DiscreteEvent->new();
my $sink = $model->add('Test::DE::Sink');
my $gen = $model->add(
    'Simulation::DiscreteEvent::Generator',
    start_at   => 2,
    interval   => sub { shift->model->time },
    message    => sub { sprintf "Now: %d", shift->model->time },
    event_name => 'message',
    limit      => 3,
    dest       => $sink,
);
    
isa_ok $gen, 'Simulation::DiscreteEvent::Generator', '$gen';

$model->run;
is 0+@events, 3, 'three events';
eq_or_diff \@events,
    [ [ 2, 'Now: 2' ], [ 4, 'Now: 4' ], [ 8, 'Now: 8' ] ],
    'events';
is $model->time, 8, 'now: 8';

{
    package Test::DE::Sink2;
    use Moose;
    BEGIN { extends 'Simulation::DiscreteEvent::Server' }
    sub message : Event {
        my $self = shift;
        push @events, $self->model->time;
    }
}

$model = Simulation::DiscreteEvent->new();
$sink = $model->add('Test::DE::Sink2');
$gen = $model->add(
    'Simulation::DiscreteEvent::Generator',
    interval   => sub { 3 },
    event_name => 'message',
    limit      => 10,
);
$gen->dest($sink);
    
isa_ok $gen, 'Simulation::DiscreteEvent::Generator', '$gen';
$model->schedule(1, $gen, 'next');
$model->schedule(2, $gen, 'next');
@events = ();
$model->run;
is 0+@events, 10, "Ten events";
eq_or_diff \@events, [ 1, 2, 4, 5, 7, 8, 10, 11, 13, 14 ], "times of events";

dies_ok {
    $model->add(
        'Simulation::DiscreteEvent::Generator',
        interval   => sub { 3 },
        event_name => 'message',
        start_at   => $model->time - 1
    );
}
'negative start_at';

$gen = $model->add(
    'Simulation::DiscreteEvent::Generator',
    interval   => sub { 3 },
    event_name => 'message',
    limit      => 10,
);
$model->send($gen, 'next');
throws_ok { $model->run } qr/destination/i, "Can't run without destination";

