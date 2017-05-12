use strict;
use warnings;

use Test::Most qw(no_plan);

use ok 'Simulation::DiscreteEvent';

my $sim = Simulation::DiscreteEvent->new;

isa_ok $sim, 'Simulation::DiscreteEvent';
is $sim->time, 0, "time is 0";

alarm 5;
$sim->run;
alarm 0;
ok 1, "simulation exited as queue empty";
is $sim->time, 0, "simulation time is still zero";

{
    package Test::DE::Server;
    use Moose;
    BEGIN {
        extends 'Simulation::DiscreteEvent::Server';
    }

    has evlog => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
    sub type { 'Test Server' }
    sub handler : Event(test) { push @{$_[0]->evlog}, $_[1] }
}

my $srv = $sim->add('Test::DE::Server');
$sim->schedule(0, $srv, 'test', 'Event1');
$sim->schedule(1, $srv, 'test', 'Event4');
$sim->schedule(2, $srv, 'test', 'Event6');
$sim->schedule(1, $srv, 'test', 'Event5');
$sim->schedule(0, $srv, 'test', 'Event2');
$sim->send($srv, 'test', 'Event3');
$sim->schedule(7, $srv, 'test', 'Event7');
$sim->schedule(7, $srv, 'test', 'Event8');

my @events = map { "Event$_" } 1..8;
eq_or_diff [ map { $_->message } @{ $sim->_events } ], \@events, "Events scheduled in the rigth order";

is $sim->run(2), 6, "6 events handled";
dies_ok { $sim->schedule(1, $srv, 'test', 'Event9') } "Can't schedule events in the past";
is 0+@{$sim->_events}, 2, "two events are still in the queue";
is $sim->time, 2, "simulation stopped at time 2";
ok $sim->step, "penultimate event handled successfully";
is 0+@{$sim->_events}, 1, "last event is in the queue";
ok $sim->step, "last event handled successfully";
is $sim->time, 7, "after last step model time is 7";
eq_or_diff $srv->evlog, \@events, "Events logged in the right order";
ok ! $sim->step, "no more events";


