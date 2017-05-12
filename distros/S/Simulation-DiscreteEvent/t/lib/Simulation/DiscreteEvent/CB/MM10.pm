package Simulation::DiscreteEvent::CB::MM10;
use Moose;
BEGIN { extends 'Simulation::DiscreteEvent::Server'; }
use Math::Random qw(random_exponential);

# server state
has busy => ( is => 'rw', default => 0 );

# arrival rate
has lambda => ( is => 'rw', required => 1 );

# serving rate
has mu => ( is => 'rw', required => 1 );

# number of served customers
has served => (
    is      => 'rw',
    traits  => ['Counter'],
    default => 0,
    handles => { inc_served => 'inc' }
);

# number of rejected customers
has rejected => (
    is      => 'rw',
    traits  => ['Counter'],
    default => 0,
    handles => { inc_rejected => 'inc' }
);

# New customerr arrived
sub arrival : Event {
    my $self = shift;
    my $next_time = $self->model->time 
        + random_exponential( 1, 1 / $self->lambda );
    $self->model->schedule( $next_time, $self, 'arrival' );
    if ( $self->busy ) {
        $self->inc_rejected;
    }
    else {
        my $srv_time = $self->model->time
            + random_exponential( 1, 1 / $self->mu );
        $self->model->schedule( $srv_time, $self, 'finished' );
        $self->busy(1);
    }
}

# Customer served
sub finish : Event(finished) {
    my $self = shift;
    $self->inc_served;
    $self->busy(0);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
