package TAEB::Action::Melee;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Direction';
with 'TAEB::Action::Role::Monster';

has '+direction' => (
    required => 1,
);

# sadly, Melee doesn't give an "In what direction?" message
sub command { 'F' . shift->direction }

sub msg_killed {
    my ($self, $monster_name) = @_;

    $self->target_tile->witness_kill($monster_name);
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;


