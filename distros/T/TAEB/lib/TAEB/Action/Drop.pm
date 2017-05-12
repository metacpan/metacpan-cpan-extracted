package TAEB::Action::Drop;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Item';

use constant command => "Da\n";

has items => (
    is  => 'ro',
    isa => 'ArrayRef',
    provided => 1,
);

# logic is elsewhere sadly

sub msg_ring {
    my $self     = shift;
    my $identity = shift;
    TAEB->log->action("Identified ".$self->item->appearance." as $identity");
    $self->item->identify_as($identity);
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

