package Reaction::UI::ViewPort::Data;

use Reaction::Class;
extends 'Reaction::UI::ViewPort';

use namespace::clean -except => [qw(meta)];

has args => ( isa => 'HashRef', is => 'ro', default => sub{{}} );

1;
