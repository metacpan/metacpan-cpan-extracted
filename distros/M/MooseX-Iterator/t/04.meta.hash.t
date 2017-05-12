#!perl

use Test::More (tests => 4);

package TestIterator;

use Moose;
use MooseX::Iterator;

has collection => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { { one => '1', two => '2', three => '3' } },
);

has iter => (
    metaclass    => 'Iterable',
    iterate_over => 'collection',
);

no Moose;

package main;
use Data::Dumper;

my $test = TestIterator->new;

my $it = $test->iter;

ok $it->does('MooseX::Iterator::Role'), 'does MooseX::Iterator::Role';

while ( $it->has_next ) {
    my $next = $it->next;

    is ref $next, 'HASH';
}
