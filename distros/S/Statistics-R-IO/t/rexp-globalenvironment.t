#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 11;
use Test::Fatal;

use Statistics::R::REXP::GlobalEnvironment;

my $env = new_ok('Statistics::R::REXP::GlobalEnvironment', [], 'new GlobalEnv');

is($env, $env, 'self equality');

my $env_2 = Statistics::R::REXP::GlobalEnvironment->new;
is($env, $env_2, 'null equality');
isnt($env, 'null', 'null inequality');

## cannot set enclosure or attributes on the global environment
like(exception {
         Statistics::R::REXP::GlobalEnvironment->new(enclosure => $env_2)
     }, qr/Global environment has an implicit enclosure/, 'setting global env enclosure');
like(exception {
         Statistics::R::REXP::GlobalEnvironment->new(attributes => { foo => 'bar', x => 42 })
     }, qr/Global environment has implicit attributes/, 'setting global env attributes');

ok(!$env->is_null, 'is not null');
ok(!$env->is_vector, 'is not vector');

is($env .'',
   'environment R_GlobalEnvironment', 'text representation');

## attributes
is_deeply($env->attributes, undef, 'default attributes');

## Perl representation
like(exception {
         $env->to_pl
     }, qr/Environments do not have a native Perl representation/,
     'Perl representation');
