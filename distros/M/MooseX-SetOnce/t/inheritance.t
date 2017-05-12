use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Moose;

use MooseX::SetOnce ();

{
    package Fruit;
    use Moose;

    has color => (
        is     => 'rw',
        traits => [ qw(SetOnce) ],
    );
}

{
    package Apple;
    use Moose;
    extends 'Fruit';
}

with_immutable {
    my $apple = Apple->new;

    is(
        exception { $apple->color('red') },
        undef,
        'SetOnce attributes can exist in a parent class',
    );

} 'Apple';

done_testing;
