package Simulation::DiscreteEvent::CB::Callcenter;

use Moose;

BEGIN { extends 'Simulation::DiscreteEvent::Server' }
with 'Simulation::DiscreteEvent::NumericState';
use Math::Random qw(random_normal);

has mu       => ( is => 'rw', isa => 'Num', default => 3 );
has sigma    => ( is => 'rw', isa => 'Num', default => 1 );
has channels => ( is => 'rw', isa => 'Int', default => 10 );
has dest => (
    is  => 'rw',
    isa => 'Simulation::DiscreteEvent::Server'
);

# generate random call duration
sub _call_duration {
    my $self = shift;
    my $n = random_normal( 1, 0, 1 );
    exp( $self->mu + $self->sigma * $n );
}

sub new_call : Event {
    my $self = shift;

    # if there's a free channel serve the call
    if ( $self->state < $self->channels ) {
        $self->state_inc;
        my $finish_time = $self->model->time + $self->_call_duration;
        $self->model->schedule( $finish_time, $self, 'served' );
    }

    # otherwise reject call
    else {
        $self->model->send( $self->dest, 'rejected' );
    }
}

sub served : Event {
    my $self = shift;
    $self->state_dec;
    $self->model->send( $self->dest, 'served' );
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
