#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 20;
use Test::Fatal;

use Statistics::R::REXP::Symbol;

my $sym = new_ok('Statistics::R::REXP::Symbol', [ name => 'sym' ], 'new symbol' );

is($sym, $sym, 'self equality');

my $sym_2 = Statistics::R::REXP::Symbol->new(name => $sym);
is($sym, $sym_2, 'symbol equality with copy');
is(Statistics::R::REXP::Symbol->new($sym_2), $sym, 'copy constructor');
is(Statistics::R::REXP::Symbol->new('sym'), $sym, 'string constructor');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::Symbol->new([1, 2, 3])
     }, qr/Attribute 'name' must be a scalar value/,
     'error-check in single-arg constructor');
like(exception {
        Statistics::R::REXP::Symbol->new(1, 2, 3)
     }, qr/odd number of arguments/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::Symbol->new(name => [1, 2, 3])
     }, qr/Attribute 'name' must be a scalar value/,
     'bad name argument');

my $sym_foo = Statistics::R::REXP::Symbol->new(name => 'foo');
isnt($sym, $sym_foo, 'symbol inequality');

is($sym->name, 'sym', 'symbol name');

ok(! $sym->is_null, 'is not null');
ok(! $sym->is_vector, 'is not vector');

is($sym .'', 'symbol `sym`', 'symbol text representation');

## attributes
is_deeply($sym->attributes, undef, 'default attributes');

my $sym_attr = Statistics::R::REXP::Symbol->new(name => 'sym',
                                                attributes => { foo => 'bar',
                                                                x => [40, 41, 42] });
is_deeply($sym_attr->attributes,
          { foo => 'bar', x => [40, 41, 42] }, 'constructed attributes');

my $sym_attr2 = Statistics::R::REXP::Symbol->new(name => 'sym',
                                                 attributes => { foo => 'bar',
                                                                 x => [40, 41, 42] });
my $another_sym_attr = Statistics::R::REXP::Symbol->new(name => 'sym',
                                                        attributes => { foo => 'bar',
                                                                        x => [40, 42, 42] });
is($sym_attr, $sym_attr2, 'equality considers attributes');
isnt($sym_attr, $sym, 'inequality considers attributes');
isnt($sym_attr, $another_sym_attr, 'inequality considers attributes deeply');

## attributes must be a hash
like(exception {
        Statistics::R::REXP::Symbol->new(attributes => 1)
     }, qr/Attribute 'attributes' must be a hash reference/,
     'setting non-HASH attributes');

## Perl representation
is_deeply($sym->to_pl,
          'sym', 'Perl representation');
