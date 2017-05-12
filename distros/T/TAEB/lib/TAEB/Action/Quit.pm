package TAEB::Action::Quit;
use TAEB::OO;
extends 'TAEB::Action';

use constant command => "#quit\n";

sub respond_quit { 'y' }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

