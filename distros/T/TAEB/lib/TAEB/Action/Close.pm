package TAEB::Action::Close;
use TAEB::OO;
extends 'TAEB::Action';
with 'TAEB::Action::Role::Direction';

use constant command => 'c';

has '+direction' => (
    required => 1,
);

__PACKAGE__->meta->make_immutable;
no TAEB::OO;

1;

