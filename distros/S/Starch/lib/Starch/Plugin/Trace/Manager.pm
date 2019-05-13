package Starch::Plugin::Trace::Manager;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForManager';

after BUILD => sub{
    my ($self) = @_;

    $self->log->trace( 'starch.manager.new' );

    return;
};

around state => sub{
    my $orig = shift;
    my $self = shift;
    my ($id) = @_;

    my $state = $self->$orig( @_ );

    $self->log->tracef(
        'starch.manager.state.%s.%s',
        defined($id) ? 'retrieved' : 'created',
        $state->id(),
    );

    return $state;
};

around generate_state_id => sub{
    my $orig = shift;
    my $self = shift;

    my $id = $self->$orig( @_ );

    $self->log->tracef(
        'starch.manager.generate_state_id.%s',
        $id,
    );

    return $id;
};

1;
