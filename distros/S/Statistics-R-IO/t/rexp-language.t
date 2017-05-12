#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 36;
use Test::Fatal;

use Statistics::R::REXP::Language;
use Statistics::R::REXP::Character;
use Statistics::R::REXP::Double;
use Statistics::R::REXP::Integer;
use Statistics::R::REXP::List;
use Statistics::R::REXP::Symbol;

my $language = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('foo'), 4, 11.2]);
my $language2 = Statistics::R::REXP::Language->new([Statistics::R::REXP::Symbol->new('foo'), 4, 11.2]);
is($language, $language2, 'language equality');

is(Statistics::R::REXP::Language->new($language2), $language, 'copy constructor');
is(Statistics::R::REXP::Language->new(Statistics::R::REXP::List->new([Statistics::R::REXP::Symbol->new('foo'), 4, 11.2])),
   $language, 'copy constructor from a vector');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::Language->new()
     }, qr/The first element must be a Symbol or Language/,
     'error-check in no-arg constructor');
like(exception {
        Statistics::R::REXP::Language->new(elements => [])
     }, qr/The first element must be a Symbol or Language/,
     'error-check in empty vec constructor');
like(exception {
        Statistics::R::REXP::Language->new(sub {1+1})
     }, qr/Attribute 'elements' must be an array reference/,
     'error-check in single-arg constructor');
like(exception {
        Statistics::R::REXP::Language->new(1, 2, 3)
     }, qr/odd number of arguments/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::Language->new([ {foo => 1, bar => 2} ])
     }, qr/The first element must be a Symbol or Language/,
     'bad call argument');
like(exception {
        Statistics::R::REXP::Language->new(elements => {foo => 1, bar => 2})
     }, qr/Attribute 'elements' must be an array reference/,
     'bad elements argument');

my $another_language = Statistics::R::REXP::Language->new([Statistics::R::REXP::Symbol->new('bla'), 4, 11.2]);
isnt($language, $another_language, 'language inequality');

my $na_heavy_language = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('bla'), ['', undef], '0']);
my $na_heavy_language2 = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('bla'), [undef, undef], 0]);
is($na_heavy_language, $na_heavy_language, 'NA-heavy language equality');
isnt($na_heavy_language, $na_heavy_language2, 'NA-heavy language inequality');

is($language .'', 'language(symbol `foo`, 4, 11.2)', 'language text representation');
is(Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('foo'), undef]) .'',
   'language(symbol `foo`, undef)', 'text representation of a singleton NA');
is(Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('bar'), [[undef]]]) .'',
   'language(symbol `bar`, [[undef]])', 'text representation of a nested singleton NA');
is($na_heavy_language .'', 'language(symbol `bla`, [, undef], 0)', 'empty string representation');

is_deeply($language->elements,
          [Statistics::R::REXP::Symbol->new('foo'), 4, 11.2], 'language contents');
is($language->elements->[2], 11.2, 'single element access');

is_deeply(Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('baz'), 4.0, '3x', 11])->elements,
          [Statistics::R::REXP::Symbol->new('baz'), 4, '3x', 11], 'constructor with non-numeric values');

my $nested_language = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('qux'), 4.0, ['b', ['cc', 44.1]], 11]);
is_deeply($nested_language->elements,
          [Statistics::R::REXP::Symbol->new('qux'), 4, ['b', ['cc', 44.1]], 11], 'nested language contents');
is_deeply($nested_language->elements->[2]->[1], ['cc', 44.1], 'nested element');
is_deeply($nested_language->elements->[3], 11, 'non-nested element');

is($nested_language .'', 'language(symbol `qux`, 4, [b, [cc, 44.1]], 11)', 
   'nested language text representation');

my $nested_rexps = Statistics::R::REXP::Language->new([
    Statistics::R::REXP::Symbol->new('quux'),
    Statistics::R::REXP::Integer->new([ 1, 2, 3]),
    Statistics::R::REXP::Language->new([
        Statistics::R::REXP::Symbol->new('a'),
        Statistics::R::REXP::Character->new(['b']),
        Statistics::R::REXP::Double->new([11]) ]),
    Statistics::R::REXP::Character->new(['foo']) ]);

is($nested_rexps .'',
   'language(symbol `quux`, integer(1, 2, 3), language(symbol `a`, character(b), double(11)), character(foo))',
   'nested language of REXPs text representation');

ok(! $language->is_null, 'is not null');
ok( $language->is_vector, 'is vector');


## attributes
is_deeply($language->attributes, undef, 'default attributes');

my $language_attr = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('fred'), 3.3, '4', 11],
                                               attributes => { foo => 'bar',
                                                               x => [40, 41, 42] });
is_deeply($language_attr->attributes,
          { foo => 'bar', x => [40, 41, 42] }, 'constructed attributes');

my $language_attr2 = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('fred'), 3.3, '4', 11],
                                                attributes => { foo => 'bar',
                                                                x => [40, 41, 42] });
my $another_language_attr = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('fred'), 3.3, '4', 11],
                                                       attributes => { foo => 'bar',
                                                                       x => [40, 42, 42] });
is($language_attr, $language_attr2, 'equality considers attributes');
isnt($language_attr, $language, 'inequality considers attributes');
isnt($language_attr, $another_language_attr, 'inequality considers attributes deeply');

## attributes must be a hash
like(exception {
        Statistics::R::REXP::Language->new(elements => [ Statistics::R::REXP::Symbol->new('foo') ],
                                           attributes => 1)
     }, qr/Attribute 'attributes' must be a hash reference/,
     'setting non-HASH attributes');

## Perl representation
is_deeply($language->to_pl,
          ['foo', 4, 11.2],
          'Perl representation');

is_deeply($na_heavy_language->to_pl,
          ['bla', ['', undef], '0'],
          'language with NAs Perl representation');

is_deeply($nested_language->to_pl,
          ['qux', 4.0, ['b', ['cc', 44.1]], 11],
          'nested languages Perl representation');

is_deeply($nested_rexps->to_pl,
          [ 'quux', [ 1, 2, 3], [ 'a', ['b'], [11] ], ['foo'] ],
          'language with nested REXPs Perl representation');

