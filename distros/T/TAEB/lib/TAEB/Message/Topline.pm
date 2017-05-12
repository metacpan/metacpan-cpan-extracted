package TAEB::Message::Topline;
use TAEB::OO;
extends 'TAEB::Message';

has text => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

