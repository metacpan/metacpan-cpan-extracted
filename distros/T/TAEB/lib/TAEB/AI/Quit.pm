package TAEB::AI::Quit;
use TAEB::OO;
extends 'TAEB::AI';

=head1 NAME

TAEB::AI::Quit - I just can't take it any more...

=cut

sub next_action { TAEB::Action::Quit->new }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

