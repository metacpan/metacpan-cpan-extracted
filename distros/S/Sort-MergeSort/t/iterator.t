#!/usr/bin/perl -w

# $Id: iterator.t 13848 2009-07-23 21:34:00Z david $

use strict;
use warnings;

use Test::More tests => 44;
use Test::NoWarnings; # Adds an extra test.

BEGIN { use_ok('Sort::MergeSort::Iterator') or die }

# Make sure we get an exception when we don't pass a code reference to the
# constructor.
eval { Sort::MergeSort::Iterator->new('woot') };
ok( my $err = $@, "Caught exception" );
like $err, qr{Argument "woot" is not a code reference at t/iterator[.]t},
    'Error should be correct';

my @items = qw(1 2 3 4 5 6);
my $i     = 0;

# Create a simple iterator object.
ok( my $iter = Sort::MergeSort::Iterator->new( sub { $items[ $i++ ] } ),
    "Create iterator" );
isa_ok( $iter, 'Sort::MergeSort::Iterator' );

# Make sure that the main methods work.
is( $iter->position, 0, 'Check initial position' );
is( $iter->peek,     1, 'Peek at first item' );
is( $iter->position, 0, 'Position should be unchanged' );
is( $iter->next,     1, 'Check first item' );
is( $iter->peek,     2, 'Peek at second item' );
is( $iter->position, 1, 'Position should now be 0' );
is( $iter->current,  1, 'Check current item is first item' );
is( $iter->next,     2, 'Check second item' );
is( $iter->peek,     3, 'Peek at third item' );
is( $iter->peek,     3, 'Peek at third item again (cached)' );
is( $iter->position, 2, 'Position should now be 1' );
is( $iter->current,  2, 'Check current item is second item' );

# Make sure that undef finishes up the list (4 tests).
my $j = 2;
while ( my $next = $iter->next ) {
    is( $next, ++$j, "Check item # $j" );
}

# Create another iterator.
my $k = 0;
ok( $iter = Sort::MergeSort::Iterator->new( sub { $items[ $k++ ] } ),
    "Create another iterator" );

# Make sure that scalar all() works.
is_deeply( scalar $iter->all, \@items, "Check scalar all()" );

# The iterator should be empty now.
is( $iter->next, undef, "Check for no more items" );

# Sneaky way to reset our test iterator.
$k = 0;

# Make sure that all() works.
is_deeply( [ $iter->all ], \@items, "Check all() returned list" );

# The iterator should be empty now.
is( $iter->next, undef, "Check for no more items" );

# Sneaky way to reset our test iterator.
$k = 0;

# Make sure that do() does its thing (6 tests).
$iter->do(
    sub {
        is( $_[0], $k, "Check do # $k" );
    }
);

# Sneaky way to reset our test iterator.
$k = 0;

# Make sure that do() sets $_ (6 tests).
$iter->do(
    sub {
        is( $_, $k, "Check do # $k" );
    }
);

# Sneaky way to reset our test iterator.
$k = 0;

# Make sure that do() does its thing and aborts when the code ref returns a
# false value (3 tests).
$iter->do(
    sub {
        return if $_[0] > 3;
        is( $_[0], $k, "Check do # $k" );
    }
);

# Make sure that destroy works properly.
ok $iter = Sort::MergeSort::Iterator->new(
    sub { undef },
    sub { ok 1, 'Destroy should be called' },
), 'Create iterator with destroy sub';

$iter = undef;
