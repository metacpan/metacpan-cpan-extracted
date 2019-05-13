package Starch::Plugin::Trace::State;
our $VERSION = '0.14';

use Moo::Role;
use strictures 2;
use namespace::clean;

with 'Starch::Plugin::ForState';

after BUILD => sub{
    my ($self) = @_;

    $self->log->tracef(
        'starch.state.new.%s',
        $self->id(),
    );

    return;
};

foreach my $method (qw(
    save delete
    reload rollback clear
    mark_clean mark_dirty
    set_expires reset_expires
    reset_id
)) {
    around $method => sub{
        my $orig = shift;
        my $self = shift;

        $self->log->tracef(
            'starch.state.%s.%s',
            $method, $self->id(),
        );

        return $self->$orig( @_ );
    };
}

1;
