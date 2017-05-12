#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;
use Test::Fatal;

use Statistics::R::REXP::EmptyEnvironment;

my $env = new_ok('Statistics::R::REXP::EmptyEnvironment', [], 'new EmptyEnv');

is($env, $env, 'self equality');

my $env_2 = Statistics::R::REXP::EmptyEnvironment->new;
is($env, $env_2, 'null equality');
isnt($env, 'null', 'null inequality');

## cannot set enclosure or attributes on the empty environment
like(exception {
         Statistics::R::REXP::EmptyEnvironment->new(frame => { })
     }, qr/Nothing can be assigned to the empty environment/, 'setting empty env contents');
like(exception {
         Statistics::R::REXP::EmptyEnvironment->new(enclosure => $env_2)
     }, qr/Empty environment has no enclosure/, 'setting empty env enclosure');
like(exception {
         Statistics::R::REXP::EmptyEnvironment->new(attributes => { foo => 'bar', x => 42 })
     }, qr/Empty environment has no attributes/, 'setting empty env attributes');

ok(!$env->is_null, 'is not null');
ok(!$env->is_vector, 'is not vector');

is($env .'',
   'environment R_EmptyEnv', 'text representation');

## attributes
is_deeply($env->attributes, undef, 'default attributes');

## Perl representation
like(exception {
         $env->to_pl
     }, qr/Environments do not have a native Perl representation/,
     'Perl representation');
