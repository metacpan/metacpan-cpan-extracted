use strict;
use warnings;

use Test::More tests => 2;

{
    package Foo;
    use Moose;
    use MooseX::Attribute::Multibuilder;

    has [ qw/ bar baz / ] => (
        traits => [ 'Multibuilder' ],
        is => 'ro',
        lazy => 1,
        multibuilder => '_build_them_all'
    );

    sub _build_them_all {
        return { bar => 'BAR', baz => 'BAZ' };
    }
}

my $foo = Foo->new;

is $foo->bar => 'BAR';
is $foo->baz => 'BAZ';

