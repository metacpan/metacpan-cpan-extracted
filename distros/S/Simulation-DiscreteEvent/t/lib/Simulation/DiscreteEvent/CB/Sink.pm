package Simulation::DiscreteEvent::CB::Sink;

use Moose;
BEGIN { extends 'Simulation::DiscreteEvent::Server' }
with 'Simulation::DiscreteEvent::Recorder';

sub served : Event {}
sub rejected : Event {}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
