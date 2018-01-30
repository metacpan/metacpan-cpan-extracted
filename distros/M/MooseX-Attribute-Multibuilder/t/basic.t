use strict;
use warnings;

use Test::More tests => 7;

{
    package Foo;
    use Moose;
    use MooseX::Attribute::Multibuilder;

    has bar => (
        traits => [ 'Multibuilder' ],
        is => 'ro',
        lazy => 1,
        predicate => 'has_bar',
        multibuilder => '_build_them_all'
    );

    has baz => (
        traits => [ 'Multibuilder' ],
        is => 'ro',
        lazy => 1,
        predicate => 'has_baz',
        multibuilder => '_build_them_all'
    );

    sub _build_them_all {
        return { bar => 'BAR', baz => 'BAZ' };
    }
}

my $foo = Foo->new;

ok !$foo->$_, "lazy and not defined" for qw/ has_bar has_baz /;

is $foo->bar => 'BAR';

ok $foo->$_, "both have been filed" for qw/ has_bar has_baz /;
is $foo->baz => 'BAZ';


subtest 'no clobbering' => sub {
    $foo = Foo->new( baz => 'nope' );

    is $foo->bar => 'BAR';
    is $foo->baz => 'nope';
}
