#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 37;
use Test::Fatal;

use Statistics::R::REXP::Expression;
use Statistics::R::REXP::Language;
use Statistics::R::REXP::Character;
use Statistics::R::REXP::Double;
use Statistics::R::REXP::Integer;
use Statistics::R::REXP::List;
use Statistics::R::REXP::Symbol;

my $empty_expression = new_ok('Statistics::R::REXP::Expression', [  ], 'new expression' );

is($empty_expression, $empty_expression, 'self equality');

my $empty_expression_2 = Statistics::R::REXP::Expression->new();
is($empty_expression, $empty_expression_2, 'empty expression equality');

my $expression = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('foo'), 4, 11.2]);
my $expression2 = Statistics::R::REXP::Expression->new([Statistics::R::REXP::Symbol->new('foo'), 4, 11.2]);
is($expression, $expression2, 'expression equality');

is(Statistics::R::REXP::Expression->new($expression2), $expression, 'copy constructor');
is(Statistics::R::REXP::Expression->new(Statistics::R::REXP::List->new([Statistics::R::REXP::Symbol->new('foo'), 4, 11.2])),
   $expression, 'copy constructor from a vector');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::Expression->new(sub {1+1})
     }, qr/Attribute 'elements' must be an array reference/,
     'error-check in single-arg constructor');
like(exception {
        Statistics::R::REXP::Expression->new(1, 2, 3)
     }, qr/odd number of arguments/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::Expression->new(elements => {foo => 1, bar => 2})
     }, qr/Attribute 'elements' must be an array reference/,
     'bad elements argument');

my $another_expression = Statistics::R::REXP::Expression->new([Statistics::R::REXP::Symbol->new('bla'), 4, 11.2]);
isnt($expression, $another_expression, 'expression inequality');

my $na_heavy_expression = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('bla'), ['', undef], '0']);
my $na_heavy_expression2 = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('bla'), [undef, undef], 0]);
is($na_heavy_expression, $na_heavy_expression, 'NA-heavy expression equality');
isnt($na_heavy_expression, $na_heavy_expression2, 'NA-heavy expression inequality');

is($expression .'', 'expression(symbol `foo`, 4, 11.2)', 'expression text representation');
is(Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('foo'), undef]) .'',
   'expression(symbol `foo`, undef)', 'text representation of a singleton NA');
is(Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('bar'), [[undef]]]) .'',
   'expression(symbol `bar`, [[undef]])', 'text representation of a nested singleton NA');
is($na_heavy_expression .'', 'expression(symbol `bla`, [, undef], 0)', 'empty string representation');

is_deeply($expression->elements,
          [Statistics::R::REXP::Symbol->new('foo'), 4, 11.2], 'expression contents');
is($expression->elements->[2], 11.2, 'single element access');

is_deeply(Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('baz'), 4.0, '3x', 11])->elements,
          [Statistics::R::REXP::Symbol->new('baz'), 4, '3x', 11], 'constructor with non-numeric values');

my $nested_expression = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('qux'), 4.0, ['b', ['cc', 44.1]], 11]);
is_deeply($nested_expression->elements,
          [Statistics::R::REXP::Symbol->new('qux'), 4, ['b', ['cc', 44.1]], 11], 'nested expression contents');
is_deeply($nested_expression->elements->[2]->[1], ['cc', 44.1], 'nested element');
is_deeply($nested_expression->elements->[3], 11, 'non-nested element');

is($nested_expression .'', 'expression(symbol `qux`, 4, [b, [cc, 44.1]], 11)', 
   'nested expression text representation');

my $nested_rexps = Statistics::R::REXP::Expression->new([
    Statistics::R::REXP::Symbol->new('quux'),
    Statistics::R::REXP::Integer->new([ 1, 2, 3]),
    Statistics::R::REXP::Language->new([
        Statistics::R::REXP::Symbol->new('a'),
        Statistics::R::REXP::Character->new(['b']),
        Statistics::R::REXP::Double->new([11]) ]),
    Statistics::R::REXP::Character->new(['foo']) ]);

is($nested_rexps .'',
   'expression(symbol `quux`, integer(1, 2, 3), language(symbol `a`, character(b), double(11)), character(foo))',
   'nested expression of REXPs text representation');

ok(! $expression->is_null, 'is not null');
ok( $expression->is_vector, 'is vector');


## attributes
is_deeply($expression->attributes, undef, 'default attributes');

my $expression_attr = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('fred'), 3.3, '4', 11],
                                               attributes => { foo => 'bar',
                                                               x => [40, 41, 42] });
is_deeply($expression_attr->attributes,
          { foo => 'bar', x => [40, 41, 42] }, 'constructed attributes');

my $expression_attr2 = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('fred'), 3.3, '4', 11],
                                                            attributes => { foo => 'bar',
                                                                            x => [40, 41, 42] });
my $another_expression_attr = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Symbol->new('fred'), 3.3, '4', 11],
                                                                   attributes => { foo => 'bar',
                                                                                   x => [40, 42, 42] });
is($expression_attr, $expression_attr2, 'equality considers attributes');
isnt($expression_attr, $expression, 'inequality considers attributes');
isnt($expression_attr, $another_expression_attr, 'inequality considers attributes deeply');

## attributes must be a hash
like(exception {
        Statistics::R::REXP::Expression->new(elements => [ Statistics::R::REXP::Symbol->new('foo') ],
                                             attributes => 1)
     }, qr/Attribute 'attributes' must be a hash reference/,
     'setting non-HASH attributes');

## Perl representation
is_deeply($expression->to_pl,
          ['foo', 4, 11.2],
          'Perl representation');

is_deeply($na_heavy_expression->to_pl,
          ['bla', ['', undef], '0'],
          'expression with NAs Perl representation');

is_deeply($nested_expression->to_pl,
          ['qux', 4.0, ['b', ['cc', 44.1]], 11],
          'nested expressions Perl representation');

is_deeply($nested_rexps->to_pl,
          [ 'quux', [ 1, 2, 3], [ 'a', ['b'], [11] ], ['foo'] ],
          'expression with nested REXPs Perl representation');

my $singleton = Statistics::R::REXP::Expression->new(elements => [Statistics::R::REXP::Integer->new([42])]);
is_deeply($singleton->to_pl,
          [[42]],
          'singleton element Perl representation');

