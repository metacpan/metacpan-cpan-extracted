use strict;
use warnings;

use Test::More 0.88;
use Test::Fatal;
use Test::Moose;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

{
package Foo;
use Moose;
use MooseX::UndefTolerant;

has 'bar' => (
    is => 'ro',
    isa => 'Num',
    init_arg => undef,
);
}

package main;

with_immutable
{
    is(exception { my $foo = Foo->new }, undef, 'constructed with no args');

    is(exception { my $foo = Foo->new(bar => undef) }, undef, 'constructed with undef value');

    is(exception { my $foo = Foo->new(bar => 1234) }, undef, 'constructed with defined value');
} 'Foo';

done_testing;
