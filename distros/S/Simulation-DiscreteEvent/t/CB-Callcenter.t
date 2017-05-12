use strict;
use warnings;
use lib 't/lib';

use Test::More qw(no_plan);
use ok 'Simulation::DiscreteEvent';

my $model = Simulation::DiscreteEvent->new;
my $gen   = $model->add('Simulation::DiscreteEvent::CB::Generator');
my $cc    = $model->add(
    'Simulation::DiscreteEvent::CB::Callcenter',
    mu       => 3.5,
    sigma    => 1,
    channels => 50,
);
my $sink = $model->add('Simulation::DiscreteEvent::CB::Sink');

$gen->dest($cc);
$cc->dest($sink);

$model->send( $gen, 'next' );
$model->run(1000);

print "Model time:   ", $model->time, "\n";
my $served   = $sink->get_number_of('served');
my $rejected = $sink->get_number_of('rejected');
print "Calls total:  ", $served + $rejected, "\n";
print "Served:       $served\n";
print "Rejected:     $rejected\n";
print "Average load: ", $cc->average_load, "\n";

