#!perl

use Test::More tests => 17;

use MooseX::Iterator;

my $test = MooseX::Iterator::Array->new( collection => [ 1, 2, 3, 4, 5, 6 ] );

my $count = 1;
while ( $test->has_next ) {
    my $peek = $test->peek;
    my $next = $test->next;

    is $next, $count, 'Current position value ' . $count;

    if ( $count < 6 ) {
        ok $test->has_next, 'has next';
    }
    else {
        ok !$test->has_next, 'does not have next';
        last;
    }

    is $peek, $count + 1, 'peek ahead of ' . $count . " ($peek)";

    $count += 1;
}
