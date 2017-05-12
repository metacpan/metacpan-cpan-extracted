use strict;
use warnings;
use Test::More;

package SimpleChained;
use Moose;

has 'regular_attr' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { 'hello'; },
);

has 'chained_attr' => (
    traits  => ['Chained'],
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { 0; },
);

has 'writer_attr' => (
    traits => ['Chained'],
    is     => 'rw',
    isa    => 'Str',
    reader => 'get_writer_attr',
    writer => 'set_writer_attr',
);

package main;

my $simple = SimpleChained->new();
is($simple->chained_attr(1)->regular_attr, 'hello', 'chained accessor attribute');
is($simple->chained_attr(0)->set_writer_attr('world')->get_writer_attr, 'world', 'chained writer attribute');

done_testing;