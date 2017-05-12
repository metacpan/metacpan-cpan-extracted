package MooseX::Async::Meta::Role;
use Moose;

extends qw(Moose::Meta::Role);

with qw(MooseX::Async::Meta::Trait);

no Moose;
1;
