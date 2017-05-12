package TAEB::Action::Open;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Direction';

use constant command => 'o';

has '+direction' => (
    required => 1,
);

sub msg_door {
    my $self = shift;
    my $type = shift;

    my $tile = $self->target_tile('closeddoor');

    if ($type eq 'locked') {
        $tile->state('locked');
    }
    elsif ($type eq 'resists') {
        $tile->state('unlocked');
    }
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

