use strict;
use warnings;
use Test::More 0.88;

do {
    package MyTrait::Labeled;
    use Moose::Role;

    has label => (
        is  => 'ro',
        isa => 'Str',
    );
};

do {
    package P::Role;
    use MooseX::Role::Parameterized;

    parameter favorite => (
        traits => ['MyTrait::Labeled'],
        label  => 'FAVE',
        isa    => 'Str',
    );

    role {
        my $p = shift;

        method faves => sub { $p->meta->get_attribute('favorite')->label . ': ' . $p->favorite };
    }
};

do {
    package Class::P::d;
    use Moose;
    with 'P::Role' => { favorite => 'ether' };
};

do {
    package Other::Class::P::d;
    use Moose;
    with 'P::Role' => { favorite => 'karen' };
};

is(Class::P::d->faves, 'FAVE: ether');
is(Other::Class::P::d->faves, 'FAVE: karen');

done_testing;
