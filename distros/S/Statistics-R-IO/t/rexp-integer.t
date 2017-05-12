#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 34;
use Test::Fatal;

use Statistics::R::REXP::Integer;
use Statistics::R::REXP::List;

my $empty_vec = new_ok('Statistics::R::REXP::Integer', [  ], 'new integer vector' );

is($empty_vec, $empty_vec, 'self equality');

my $empty_vec_2 = Statistics::R::REXP::Integer->new();
is($empty_vec, $empty_vec_2, 'empty integer vector equality');

my $vec = Statistics::R::REXP::Integer->new(elements => [3, 4, 11]);
my $vec2 = Statistics::R::REXP::Integer->new([3, 4, 11]);
is($vec, $vec2, 'integer vector equality');

is(Statistics::R::REXP::Integer->new($vec2), $vec, 'copy constructor');
is(Statistics::R::REXP::Integer->new(Statistics::R::REXP::List->new([3.3, [4, '11']])),
   $vec, 'copy constructor from a vector');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::Integer->new(sub {1+1})
     }, qr/Attribute 'elements' must be an array reference/,
     'error-check in single-arg constructor');
like(exception {
        Statistics::R::REXP::Integer->new(1, 2, 3)
     }, qr/odd number of arguments/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::Integer->new(elements => {foo => 1, bar => 2})
     }, qr/Attribute 'elements' must be an array reference/,
     'bad elements argument');

my $another_vec = Statistics::R::REXP::Integer->new(elements => [3, 4, 1]);
isnt($vec, $another_vec, 'integer vector inequality');

## TODO: undef == 0!

my $truncated_vec = Statistics::R::REXP::Integer->new(elements => [3.3, 4.0, 11]);
is($truncated_vec, $vec, 'constructing from floats');

my $na_heavy_vec = Statistics::R::REXP::Integer->new(elements => [11.3, '', undef, '0.0']);
my $na_heavy_vec2 = Statistics::R::REXP::Integer->new(elements => [11, 0, undef, 0]);
is($na_heavy_vec, $na_heavy_vec, 'NA-heavy vector equality');
isnt($na_heavy_vec, $na_heavy_vec2, 'NA-heavy vector inequality');

is($empty_vec .'', 'integer()', 'empty integer vector text representation');
is($vec .'', 'integer(3, 4, 11)', 'integer vector text representation');
is(Statistics::R::REXP::Integer->new(elements => [undef]) .'',
   'integer(undef)', 'text representation of a singleton NA');
is($na_heavy_vec .'', 'integer(11, undef, undef, 0)', 'empty numbers representation');

is_deeply($empty_vec->elements, [], 'empty integer vector contents');
is_deeply($vec->elements, [3, 4, 11], 'integer vector contents');
is($vec->elements->[2], 11, 'single element access');
is_deeply(Statistics::R::REXP::Integer->new([-1, -1.5, -1.6, -1.4])->elements,
          [-1, -2, -2, -1], 'negative integer vector contents');

is_deeply(Statistics::R::REXP::Integer->new(elements => [3.3, 4.0, '3x', 11])->elements,
          [3, 4, undef, 11], 'constructor with non-numeric values');

is_deeply(Statistics::R::REXP::Integer->new(elements => [3.3, 4.0, [7, [20.9, 44.1]], 11])->elements,
          [3, 4, 7, 21, 44, 11], 'constructor from nested arrays');

ok(! $empty_vec->is_null, 'is not null');
ok( $empty_vec->is_vector, 'is vector');


## attributes
is_deeply($vec->attributes, undef, 'default attributes');

my $vec_attr = Statistics::R::REXP::Integer->new(elements => [3, 4, 11],
                                                 attributes => { foo => 'bar',
                                                                 x => [40, 41, 42] });
is_deeply($vec_attr->attributes,
          { foo => 'bar', x => [40, 41, 42] }, 'constructed attributes');

my $vec_attr2 = Statistics::R::REXP::Integer->new(elements => [3, 4, 11],
                                                  attributes => { foo => 'bar',
                                                                  x => [40, 41, 42] });
my $another_vec_attr = Statistics::R::REXP::Integer->new(elements => [3, 4, 11],
                                                         attributes => { foo => 'bar',
                                                                         x => [40, 42, 42] });
is($vec_attr, $vec_attr2, 'equality considers attributes');
isnt($vec_attr, $vec, 'inequality considers attributes');
isnt($vec_attr, $another_vec_attr, 'inequality considers attributes deeply');

## attributes must be a hash
like(exception {
        Statistics::R::REXP::Integer->new(attributes => 1)
     }, qr/Attribute 'attributes' must be a hash reference/,
     'setting non-HASH attributes');

## Perl representation
is_deeply($empty_vec->to_pl,
          [], 'empty vector Perl representation');

is_deeply($vec->to_pl,
          [3, 4, 11], 'Perl representation');

is_deeply($na_heavy_vec->to_pl,
          [11, undef, undef, 0], 'NA-heavy Perl representation');

