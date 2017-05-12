#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;
use Test::Fatal;

use Statistics::R::REXP::S4;

my $s4 = new_ok('Statistics::R::REXP::S4', [ class => 'foo', package => 'bar' ], 'new symbol' );

is($s4, $s4, 'self equality');

my $s4_2 = Statistics::R::REXP::S4->new(class => 'foo', package => 'bar');
is($s4, $s4_2, 'symbol equality with copy');
is(Statistics::R::REXP::S4->new($s4_2), $s4, 'copy constructor');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::S4->new(class => [1, 2, 3])
     }, qr/Attribute 'class' must be a scalar value/,
     'bad class argument');
like(exception {
        Statistics::R::REXP::S4->new(1, 2, 3)
     }, qr/odd number of elements/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::S4->new(class => "foo",
                                     package => "bar",
                                     slots => [1, 2, 3])
     }, qr/Attribute 'slots' must be a reference to a hash of REXPs/,
     'bad slots argument');
like(exception {
        Statistics::R::REXP::S4->new(class => 'foo', package => [1, 2, 3])
     }, qr/Attribute 'package' must be a scalar value/,
     'bad package argument');

my $s4_foo = Statistics::R::REXP::S4->new(class => 'quux', package => 'bar');
isnt($s4, $s4_foo, 'symbol inequality');

is($s4->class, 'foo', 'object class');
is($s4->package, 'bar', 'object package');
is_deeply($s4->slots, {}, 'object slots');

ok(! $s4->is_null, 'is not null');
ok(! $s4->is_vector, 'is not vector');

is($s4 .'', "object of class 'foo' (package bar) with 0 slots", 
   'symbol text representation');

## attributes
is_deeply($s4->attributes, undef, 'default attributes');

my $s4_attr = Statistics::R::REXP::S4->new(class => 'foo', package => 'bar',
                                                attributes => { foo => 'bar',
                                                                x => [40, 41, 42] });
is_deeply($s4_attr->attributes,
          { foo => 'bar', x => [40, 41, 42] }, 'constructed attributes');

my $s4_attr2 = Statistics::R::REXP::S4->new(class => 'foo', package => 'bar',
                                                 attributes => { foo => 'bar',
                                                                 x => [40, 41, 42] });
my $another_sym_attr = Statistics::R::REXP::S4->new(class => 'foo', package => 'bar',
                                                        attributes => { foo => 'bar',
                                                                        x => [40, 42, 42] });
is($s4_attr, $s4_attr2, 'equality considers attributes');
isnt($s4_attr, $s4, 'inequality considers attributes');
isnt($s4_attr, $another_sym_attr, 'inequality considers attributes deeply');

## attributes must be a hash
like(exception {
        Statistics::R::REXP::S4->new(attributes => 1)
     }, qr/Attribute 'attributes' must be a hash reference/,
     'setting non-HASH attributes');

## Perl representation
is_deeply($s4->to_pl,
          {class => 'foo', package => 'bar', slots => {}},
          'Perl representation');
