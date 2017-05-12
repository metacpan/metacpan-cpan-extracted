#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 12;
use Test::Fatal;

use Statistics::R::REXP::BaseEnvironment;

my $env = new_ok('Statistics::R::REXP::BaseEnvironment', [], 'new BaseEnv');

is($env, $env, 'self equality');

my $env_2 = Statistics::R::REXP::BaseEnvironment->new;
is($env, $env_2, 'null equality');
isnt($env, 'null', 'null inequality');

## cannot set enclosure or attributes on the base environment
like(exception {
         Statistics::R::REXP::BaseEnvironment->new(frame => { })
     }, qr/Nothing can be assigned to the base environment/, 'setting base env contents');
like(exception {
         Statistics::R::REXP::BaseEnvironment->new(enclosure => $env_2)
     }, qr/Base environment has an implicit enclosure/, 'setting base env enclosure');
like(exception {
         Statistics::R::REXP::BaseEnvironment->new(attributes => { foo => 'bar', x => 42 })
     }, qr/Base environment has implicit attributes/, 'setting base env attributes');

ok(!$env->is_null, 'is not null');
ok(!$env->is_vector, 'is not vector');

is($env .'',
   'environment R_BaseEnv', 'text representation');

## attributes
is_deeply($env->attributes, undef, 'default attributes');

## Perl representation
like(exception {
         $env->to_pl
     }, qr/Environments do not have a native Perl representation/,
     'Perl representation');
