#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 19;
use Test::Fatal;

use Statistics::R::REXP::Environment;

use Scalar::Util qw(refaddr);

my $env = new_ok('Statistics::R::REXP::Environment', [ name => 'sym' ], 'new environment' );

is($env, $env, 'self equality');

my $env_2 = Statistics::R::REXP::Environment->new(name => $env);
is($env, $env_2, 'environment equality with copy');
is(Statistics::R::REXP::Environment->new($env_2), $env, 'copy constructor');

## error checking in constructor arguments
like(exception {
        Statistics::R::REXP::Environment->new([1, 2, 3])
     }, qr/HASH data or a Statistics::R::REXP::Environment/,
     'error-check in single-arg constructor');
like(exception {
        Statistics::R::REXP::Environment->new(1, 2, 3)
     }, qr/odd number of arguments/,
     'odd constructor arguments');

## Frame must be a hash of REXPs
like(exception {
        Statistics::R::REXP::Environment->new(frame => {foo => 1, bar => 3})
     }, qr/Attribute 'frame' must be a reference to a hash of REXPs/,
     'error-check in single-arg constructor');
## Enclosure must be another Environment
like(exception {
         Statistics::R::REXP::Environment->new(enclosure => 'foo')
     }, qr/Attribute 'enclosure' must be an instance of Environment/,
     'bad env enclosure');

my $env_foo = Statistics::R::REXP::Environment->new(enclosure => $env);
isnt($env, $env_foo, 'environment inequality');

ok(! $env->is_null, 'is not null');
ok(! $env->is_vector, 'is not vector');

is($env .'',
   'environment 0x' . sprintf('%x', refaddr $env),
   'environment text representation');

## attributes
is_deeply($env->attributes, undef, 'default attributes');

my $env_attr = Statistics::R::REXP::Environment->new(name => 'sym',
                                                attributes => { foo => 'bar',
                                                                x => [40, 41, 42] });
is_deeply($env_attr->attributes,
          { foo => 'bar', x => [40, 41, 42] }, 'constructed attributes');

my $env_attr2 = Statistics::R::REXP::Environment->new(name => 'sym',
                                                 attributes => { foo => 'bar',
                                                                 x => [40, 41, 42] });
my $another_sym_attr = Statistics::R::REXP::Environment->new(name => 'sym',
                                                        attributes => { foo => 'bar',
                                                                        x => [40, 42, 42] });
is($env_attr, $env_attr2, 'equality considers attributes');
isnt($env_attr, $env, 'inequality considers attributes');
isnt($env_attr, $another_sym_attr, 'inequality considers attributes deeply');

## attributes must be a hash
like(exception {
        Statistics::R::REXP::Environment->new(attributes => 1)
     }, qr/Attribute 'attributes' must be a hash reference/,
     'setting non-HASH attributes');

## Perl representation
like(exception {
         $env->to_pl
     }, qr/Environments do not have a native Perl representation/,
     'Perl representation');
