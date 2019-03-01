package Starch::Plugin::Trace::Manager;
use 5.008001;
use strictures 2;
our $VERSION = '0.12';

use Moo::Role;
use namespace::clean;

with qw(
    Starch::Plugin::ForManager
);

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
