#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 21;
use Test::Fatal;

use Statistics::R::REXP::Closure;
use Statistics::R::REXP::Language;
use Statistics::R::REXP::Character;
use Statistics::R::REXP::Double;
use Statistics::R::REXP::Integer;
use Statistics::R::REXP::List;
use Statistics::R::REXP::Symbol;
use Statistics::R::REXP::Null;

my $closure = Statistics::R::REXP::Closure->new(body => Statistics::R::REXP::Null->new);
my $closure2 = Statistics::R::REXP::Closure->new(body => Statistics::R::REXP::Null->new);
is($closure, $closure2, 'closure equality');

is(Statistics::R::REXP::Closure->new($closure2), $closure, 'copy constructor');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::Closure->new()
     }, qr/Attribute \(body\) is required/,
     'error-check in no-arg constructor');
like(exception {
        Statistics::R::REXP::Closure->new([1, 2, 3])
     }, qr/HASH data or a Statistics::R::REXP::Closure/,
     'error-check in single-arg constructor');
like(exception {
        Statistics::R::REXP::Closure->new(1, 2, 3)
     }, qr/odd number of arguments/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::Closure->new(args => [],
                                          defaults => [undef], 
                                          body => Statistics::R::REXP::Null->new)
     }, qr/argument names don't match their defaults/,
     'odd constructor arguments');
like(exception {
        Statistics::R::REXP::Closure->new(body => {foo => 1, bar => 2})
     }, qr/Attribute 'body' must be a reference to an instance of Statistics::R::REXP/,
     'bad body argument');
like(exception {
         Statistics::R::REXP::Closure->new(body => Statistics::R::REXP::Integer->new([42]),
                                           environment => 'foo')
     }, qr/Attribute 'environment' must be an instance of Environment/,
     'bad env enclosure');

my $another_closure = Statistics::R::REXP::Closure->new(body => Statistics::R::REXP::Symbol->new('foo'));
isnt($closure, $another_closure, 'closure inequality');

my $args_closure = Statistics::R::REXP::Closure->new(args => ['foo'],
                                                     body => Statistics::R::REXP::Symbol->new('foo'));
isnt($args_closure, $another_closure, 'args inequality');

# my $na_heavy_language = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('bla'), ['', undef], '0']);
# my $na_heavy_language2 = Statistics::R::REXP::Language->new(elements => [Statistics::R::REXP::Symbol->new('bla'), [undef, undef], 0]);
# is($na_heavy_language, $na_heavy_language, 'NA-heavy language equality');
# isnt($na_heavy_language, $na_heavy_language2, 'NA-heavy language inequality');

is($closure .'', 'function() NULL', 'closure text representation');
is($args_closure .'', 'function(foo) symbol `foo`', 'closure text representation');

ok(! $closure->is_null, 'is not null');
ok(! $closure->is_vector, 'is not vector');


## attributes
is_deeply($closure->attributes, undef, 'default attributes');

my $closure_attr = Statistics::R::REXP::Closure->new(body => Statistics::R::REXP::Null->new,
                                                     attributes => { foo => 'bar',
                                                                     x => [40, 41, 42] });
is_deeply($closure_attr->attributes,
          { foo => 'bar', x => [40, 41, 42] }, 'constructed attributes');

my $closure_attr2 = Statistics::R::REXP::Closure->new(body => Statistics::R::REXP::Null->new,
                                                      attributes => { foo => 'bar',
                                                                      x => [40, 41, 42] });
my $another_closure_attr = Statistics::R::REXP::Closure->new(body => Statistics::R::REXP::Null->new,
                                                             attributes => { foo => 'bar',
                                                                             x => [40, 42, 42] });
is($closure_attr, $closure_attr2, 'equality considers attributes');
isnt($closure_attr, $closure, 'inequality considers attributes');
isnt($closure_attr, $another_closure_attr, 'inequality considers attributes deeply');

## attributes must be a hash
like(exception {
        Statistics::R::REXP::Closure->new(body => [ Statistics::R::REXP::Symbol->new('foo') ],
                                          attributes => 1)
     }, qr/Attribute 'attributes' must be a hash reference/,
     'setting non-HASH attributes');

## Perl representation
like(exception {
         $closure->to_pl
     }, qr/Closures do not have a native Perl representation/,
     'Perl representation');
