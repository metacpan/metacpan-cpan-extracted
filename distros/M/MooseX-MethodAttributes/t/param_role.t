use strict;
use warnings;

use Test::More;
use Test::Requires 'MooseX::Role::Parameterized';

package Foo;
use MooseX::Role::Parameterized -traits => 'MooseX::MethodAttributes::Role::Meta::Role';

parameter foo => (
    isa => "Str",
);

role {
    my $p = shift;

    method test_foo => sub {
        my ($self, $should_be) = @_;
        package main;
        is $p->foo, $should_be, 'parameter is correct';
    };
};

package UseFoo;
use Moose;

with Foo => { foo => 23 };

package main;

UseFoo->new->test_foo(23);

done_testing;
