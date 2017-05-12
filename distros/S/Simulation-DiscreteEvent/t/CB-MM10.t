use Test::More qw(no_plan);
use lib 't/lib';

use strict;
use warnings;

use Simulation::DiscreteEvent;

my $model = Simulation::DiscreteEvent->new;

my $server = $model->add(
    "Simulation::DiscreteEvent::CB::MM10",
    lambda => 2,
    mu     => 3,
);

$model->send( $server, "arrival" );

$model->run(1000);

print "Served customers:    ", $server->served,   "\n";
print "Rejected customers:  ", $server->rejected, "\n";
print "Customers loss rate: ", $server->rejected / ( $server->served + $server->rejected ), "\n";

my $loss_rate = $server->rejected / ( $server->served + $server->rejected );

ok abs($loss_rate - 0.4) < 0.1, 'Loss rate is correct';
is $model->time, 1000, 'Model time is 1000';
