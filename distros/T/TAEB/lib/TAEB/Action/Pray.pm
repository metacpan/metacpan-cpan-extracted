package TAEB::Action::Pray;
use TAEB::OO;
extends 'TAEB::Action';

use constant command => "#pray\n";

sub done {
    TAEB->last_prayed(TAEB->turn);
}

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

