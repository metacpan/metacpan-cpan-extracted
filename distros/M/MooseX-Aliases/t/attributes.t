#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Test::Moose;

my ($foo_called, $baz_called);

{
    package MyTest;
    use Moose;
    use MooseX::Aliases;

    has foo => (
        is      => 'rw',
        alias   => 'bar',
        trigger => sub { $foo_called++ },
    );

    has baz => (
        is      => 'rw',
        alias   => [qw/quux quuux/],
        trigger => sub { $baz_called++ },
    );
}

with_immutable {
    ($foo_called, $baz_called) = (0, 0);
    my $t = MyTest->new;
    $t->foo(1);
    $t->bar(1);
    $t->baz(1);
    $t->quux(1);
    $t->quuux(1);
    is($foo_called, 2, 'all aliased methods were called from foo');
    is($baz_called, 3, 'all aliased methods were called from baz');
} 'MyTest';
