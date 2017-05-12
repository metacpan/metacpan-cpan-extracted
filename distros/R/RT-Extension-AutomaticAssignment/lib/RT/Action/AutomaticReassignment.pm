package RT::Action::AutomaticReassignment;
use strict;
use warnings;
use base 'RT::Action::AutomaticAssignment';

# any owner is fine
sub _PrepareOwner {
    my $self = shift;

    return 1;
}

1;

