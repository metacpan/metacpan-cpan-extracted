package TAEB::Message::Report::Saved;
use TAEB::OO;
extends 'TAEB::Message::Report';

sub as_string { "Saved.\n" }

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

