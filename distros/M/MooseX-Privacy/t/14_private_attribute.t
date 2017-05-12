use strict;
use warnings;

use Test::More tests => 10;
use Test::Exception;
use Test::Moose;

package Foo;
use Moose;
use MooseX::Privacy;

has foo => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => 'test',
    traits  => [qw/Private/]
);

sub bar {
    my $self = shift;
    $self->foo('bar');
    $self->foo;
}

package Bar;
use Moose;

has bar => (
    is => 'rw',
    isa => 'Str',
    traits => [qw/Private/]
);

package main;

with_immutable {
    ok my $foo = Foo->new();

    dies_ok { $foo->foo };
    ok $foo->bar;
    is scalar @{ $foo->meta->local_private_attributes }, 1;
    ok my $bar = Bar->new();
}
(qw/Foo Bar/);
