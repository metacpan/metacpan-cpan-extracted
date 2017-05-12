package TAEB::AI::SteadyState;
use TAEB::OO;
extends 'TAEB::AI';

=head1 NAME

TAEB::AI::SteadyState - Sit there doing nothing, for benchmarking purposes

=cut

sub next_action { TAEB::Action::Search->new(iterations => 1) }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

