#!perl

use strict;
use warnings;

package Foo;
use Moose;
use MooseX::Types::Ro qw(RoArrayRef RoHashRef);

has array => ( is => 'ro', isa => RoArrayRef, coerce => 1 );
has hash => ( is => 'ro', isa => RoHashRef, coerce => 1 );

package main;

use Test::More;
use Test::Exception;

my $foo = Foo->new(array => [1, 2, 3], hash => { foo => 1, bar => 2 });

foreach my $test (
    sub { $foo->array->[0] = 42 },
    sub { $foo->array->[0] += 42 },
    sub { $foo->array->[0] =~ s/42/69/ },
    sub { $foo->array->[3] = 42 },
    sub { push @{$foo->array}, 42 },
    sub { shift @{$foo->array} },
    sub { $foo->hash->{foo} = 42 },
    sub { $foo->hash->{foo} += 42 },
    sub { $foo->hash->{foo} =~ s/42/69/ },
) {
    &throws_ok( $test, qr/Modification of a read-only value attempted/ );
}

foreach my $test (
    sub { $foo->hash->{baz} = 42 },
    sub { $foo->hash->{baz} },
    sub { delete $foo->hash->{foo} },
) {
    &throws_ok( $test, qr/Attempt to \w+ (readonly|disallowed) key '\w+' (in|from) a restricted hash/ );
}

done_testing;
