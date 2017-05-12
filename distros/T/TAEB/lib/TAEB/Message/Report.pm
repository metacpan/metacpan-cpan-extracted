package TAEB::Message::Report;
use TAEB::OO;
extends 'TAEB::Message';

use overload (
    q{""}    => 'as_string',
    fallback => 1,
);

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

