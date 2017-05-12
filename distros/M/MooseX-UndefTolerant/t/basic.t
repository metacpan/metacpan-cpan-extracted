use strict;
use warnings;

use Test::More 0.88;
use Test::Moose;

{
package Foo;
use Moose;
use MooseX::UndefTolerant;

has 'bar' => (
    is => 'ro',
    isa => 'Num',
    predicate => 'has_bar'
);

}

package main;

with_immutable {
    {
        my $foo = Foo->new;
        ok(!$foo->has_bar);
    }

    {
        my $foo = Foo->new(bar => undef);
        ok(!$foo->has_bar);
    }

    {
        my $foo = Foo->new(bar => 1234);
        cmp_ok($foo->bar, 'eq', 1234);
        ok($foo->has_bar);
    }
} 'Foo';

done_testing;
