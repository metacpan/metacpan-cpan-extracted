package Simulation::DiscreteEvent::CB::Generator;

use Moose;
BEGIN { extends 'Simulation::DiscreteEvent::Server'; }

use Math::Random qw(random_exponential);

has rate => ( is => 'rw', isa => 'Num', default => 1 );
has dest => ( is => 'rw', isa => 'Simulation::DiscreteEvent::Server' );

sub next : Event {
    my $self = shift;
    $self->model->send( $self->dest, 'new_call' );
    my $next_time = $self->model->time 
        + random_exponential( 1, 1 / $self->rate );
    $self->model->schedule( $next_time, $self, 'next' );
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

