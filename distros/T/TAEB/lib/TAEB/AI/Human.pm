package TAEB::AI::Human;
use TAEB::OO;
extends 'TAEB::AI';

use constant is_human_controlled => 1;

=head1 NAME

TAEB::AI::Human - the only AI that has a chance

=head2 next_action TAEB -> STRING

This will consult a magic 8-ball to determine what move to make next.

=cut

sub next_action {
    while (1) {
        my $c = TAEB->get_key;

        if ($c eq "~") {
            TAEB->notify(TAEB->keypress(TAEB->get_key));
        }
        else {
            return TAEB::Action->new_action(custom => string => $c);
        }
    }
}

=head1 IDEA BY

arcanehl

=cut

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

