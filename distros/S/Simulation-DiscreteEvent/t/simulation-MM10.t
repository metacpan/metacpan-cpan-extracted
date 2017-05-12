use strict;
use warnings;

use Test::More qw(no_plan);

use ok 'Simulation::DiscreteEvent';

{
    package Test::DE::Generator;
    use Moose;
    BEGIN {
        extends 'Simulation::DiscreteEvent::Server';
    }

    has rate => ( is => 'rw', isa => 'Num', default => 0.7 );
    has dst => ( is => 'rw', isa => 'Simulation::DiscreteEvent::Server' );
    has limit => ( is => 'rw', isa => 'Num', default => '1000' );

    sub next : Event(next) {
        my $self = shift;
        $self->model->send($self->dst, 'customer_new');
        my $limit = $self->limit - 1;
        return unless $limit;
        $self->limit($limit);
        my $next_time = $self->model->time - log(1 - rand) / $self->rate;
        $self->model->schedule($next_time, $self, 'next');
    }
}

{
    package Test::DE::Server;
    use Moose;
    BEGIN {
        extends 'Simulation::DiscreteEvent::Server';
    }
    with 'Simulation::DiscreteEvent::NumericState';

    has rate => ( is => 'rw', isa => 'Num', default => 1 );
    has dest => ( is => 'rw', isa => 'Simulation::DiscreteEvent::Server' );
    has busy => ( is => 'rw', isa => 'Bool' );

    sub cust_new : Event(customer_new) {
        my $self = shift;
        if($self->state) {
            $self->model->send($self->dest, 'customer_rejected');
        }
        else {
            $self->state(1);
            my $end_time = $self->model->time - log(1 - rand) / $self->rate;
            $self->model->schedule($end_time, $self, 'customer_served');
        }
    }

    sub cust_served : Event(customer_served) {
        my $self = shift;
        $self->model->send($self->dest, 'customer_served');
        $self->state(0);
    }
}

{
    package Test::DE::Sink;
    use Moose;
    BEGIN {
        extends 'Simulation::DiscreteEvent::Server';
    }
    with 'Simulation::DiscreteEvent::Recorder';

    sub served { shift->get_number_of('customer_served') }
    sub rejected { shift->get_number_of('customer_rejected') }
    sub cust_served : Event(customer_served) {}
    sub cust_rejected : Event(customer_rejected) {}
}

my $model = Simulation::DiscreteEvent->new;

# add server to model
my $server = $model->add('Test::DE::Server');
is $server->model, $model, "Server's model is correct";

# add customers generator to model
my $generator = $model->add('Test::DE::Generator', rate => 1, dst => $server, limit => 10000 );
is $generator->rate, 1, "Generator rate is 1";

# add sink to the model
my $sink = $model->add('Test::DE::Sink');
$server->dest($sink);

ok !defined($server->average_load), "Average load is undef when time is 0";

# generate first customer
$generator->next;
is 0+@{$model->_events}, 2, "Two events scheduled";

# run simulation
$model->run;

is $sink->served + $sink->rejected, 10000, "Sum of customers is 10000";
ok $sink->served < 5500, "About half of customers were served";
ok $sink->rejected < 5500, "About half of customers were rejected";
ok $model->time > 7000, "Model time is greater than 7000";

my @state = $server->state_data;
is_deeply $state[0], [0, 0], "First state record is [0, 0]";
is 0+@state, 2 * $sink->served + 1, "Correct number of state change records";
ok $server->average_load > 0.45, "average load is about 50%";
ok $server->average_load < 0.55, "average load is about 50%";


