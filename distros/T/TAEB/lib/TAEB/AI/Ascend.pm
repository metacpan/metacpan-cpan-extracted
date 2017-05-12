package TAEB::AI::Ascend;
use TAEB::OO;
extends 'TAEB::AI';

=head1 NAME

TAEB::AI::Ascend - Ascend in one line of code

=cut

# This is actually useful for testing the end-of-game sequence, but it's also
# here because, well, ascend
sub next_action { TAEB::Action::Ascend->new }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

