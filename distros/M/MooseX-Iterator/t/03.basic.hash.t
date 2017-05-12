#!perl

use Test::More (tests => 4);

use MooseX::Iterator;

my $test =
  MooseX::Iterator::Hash->new(
    collection => { one => '1', two => '2', three => '3' } );

ok $test->does('MooseX::Iterator::Role'), 'does MooseX::Iterator::Role';

while ( $test->has_next ) {
    my $next = $test->next;

    is ref $next, 'HASH';
}
