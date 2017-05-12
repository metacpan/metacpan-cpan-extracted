use strict;
use warnings;

use Test::More;
BEGIN {
    eval "use Test::LeakTrace";
    plan skip_all => 'This test requires Test::LeakTrace' if $@;
    plan 'no_plan';
}

use ok 'Simulation::DiscreteEvent';

my $invalid_object = {};

{
    package Test::DE::Server;
    use Moose;
    BEGIN { extends 'Simulation::DiscreteEvent::Server' };
    with 'Simulation::DiscreteEvent::NumericState';
    with 'Simulation::DiscreteEvent::Recorder';
 
    sub type { 'Test Server' }
    sub start : Event(start) { return 'Started' }
    no Moose;
    __PACKAGE__->meta->make_immutable;
}

no_leaks_ok {
    my $model = Simulation::DiscreteEvent->new;
    $model->add('Test::DE::Server');
} 'no memory leaks';

