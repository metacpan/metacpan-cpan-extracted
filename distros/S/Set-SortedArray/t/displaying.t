#!perl

use Test::More tests => 5;

require_ok('Set::SortedArray');

$set = Set::SortedArray->new(qw/ a b c /);
is( $set->as_string, '(a b c)', 'as_string' );
is( "$set",          '(a b c)', 'as_string overloaded' );

Set::SortedArray->as_string_callback(
    sub { '[' . join( '-', $_[0]->members ) . ']' } );

is( $set->as_string, '[a-b-c]', 'as_string altered' );
is( "$set",          '[a-b-c]', 'as_string altered overloaded' );
