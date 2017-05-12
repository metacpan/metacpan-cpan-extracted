#!perl

use Test::More (no_plan);

package TestIterator;

use Moose;
use MooseX::Iterator;

has numbers => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [ 5, 6, 7, 8, 9, 10 ] },
);

has iter => (
    metaclass    => 'Iterable',
    iterate_over => 'numbers',
);

no Moose;

package main;

my $test = TestIterator->new;

my $it = $test->iter;

my $count = 5;
while ( $it->has_next ) {
    my $peek = $it->peek;
    my $next = $it->next;

    is $next, $count, 'Current position value ' . $count;

    if ( $count < 10 ) {
        ok $it->has_next, 'has next';
    }
    else {
        ok !$it->has_next, 'does not have next';
        last;
    }

    is $peek, $count + 1, 'peek ahead of ' . $count . " ($peek)";

    $count += 1;
}
