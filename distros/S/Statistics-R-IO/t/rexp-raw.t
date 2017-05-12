#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 21;
use Test::Fatal;

use Statistics::R::REXP::Raw;
use Statistics::R::REXP::List;

my $empty_vec = new_ok('Statistics::R::REXP::Raw', [  ], 'new raw vector' );

is($empty_vec, $empty_vec, 'self equality');

my $empty_vec_2 = Statistics::R::REXP::Raw->new();
is($empty_vec, $empty_vec_2, 'empty raw vector equality');

my $vec = Statistics::R::REXP::Raw->new(elements => [3, 4, 11]);
my $vec2 = Statistics::R::REXP::Raw->new([3, 4, 11]);
is($vec, $vec2, 'raw vector equality');

is(Statistics::R::REXP::Raw->new($vec2), $vec, 'copy constructor');
is(Statistics::R::REXP::Raw->new(Statistics::R::REXP::List->new([3.3, [4, '11']])),
   $vec, 'copy constructor from a vector');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::Raw->new(sub {1+1})
     }, qr/Attribute 'elements' must be an array reference/,
     'error-check in single-arg constructor');
like(exception {
        Statistics::R::REXP::Raw->new(1, 2, 3)
     }, qr/odd number of arguments/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::Raw->new(elements => {foo => 1, bar => 2})
     }, qr/Attribute 'elements' must be an array reference/,
     'bad elements argument');
like(exception {
        Statistics::R::REXP::Raw->new([-1])
     }, qr/Elements of raw vectors must be 0-255/,
     'elements range');

my $another_vec = Statistics::R::REXP::Raw->new(elements => [3, 4, 1]);
isnt($vec, $another_vec, 'raw vector inequality');

my $truncated_vec = Statistics::R::REXP::Raw->new(elements => [3.3, 4.0, 11]);
is($truncated_vec, $vec, 'constructing from floats');

is_deeply($empty_vec->elements, [], 'empty raw vector contents');
is_deeply($vec->elements, [3, 4, 11], 'raw vector contents');
is($vec->elements->[2], 11, 'single element access');

ok(! $empty_vec->is_null, 'is not null');
ok( $empty_vec->is_vector, 'is vector');

## attributes
is_deeply($vec->attributes, undef, 'default attributes');

## cannot set attributes on Raw
like(exception {
        Statistics::R::REXP::Raw->new(attributes => { foo => 'bar', x => 42 })
     }, qr/Raw vectors cannot have attributes/, 'setting raw attributes');

## Perl representation
is_deeply($empty_vec->to_pl,
          [], 'empty vector Perl representation');

is_deeply($vec->to_pl,
          [3, 4, 11], 'Perl representation');
