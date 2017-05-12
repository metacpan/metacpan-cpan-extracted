package TAEB::Message::Report::CouldNotStart;
use TAEB::OO;
extends 'TAEB::Message::Report';

sub as_string { "Cannot start game; please check NetHack is working properly.\n" }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

