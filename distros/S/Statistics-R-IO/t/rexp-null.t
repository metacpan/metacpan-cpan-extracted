#!perl -T
use 5.010;
use strict;
use warnings FATAL => 'all';

use Test::More tests => 10;
use Test::Fatal;

use Statistics::R::REXP::Null;

my $null = new_ok('Statistics::R::REXP::Null', [], 'new null');

is($null, $null, 'self equality');

my $null_2 = Statistics::R::REXP::Null->new;
is($null, $null_2, 'null equality');
isnt($null, 'null', 'null inequality');

ok($null->is_null, 'is null');
ok(! $null->is_vector, 'is not vector');

is($null .'', 'NULL', 'null text representation');

## attributes
is_deeply($null->attributes, undef, 'default attributes');

## cannot set attributes on Null
like(exception {
        Statistics::R::REXP::Null->new(attributes => { foo => 'bar', x => 42 })
     }, qr/Null cannot have attributes/, 'setting null attributes');

## Perl representation
is_deeply($null->to_pl,
          undef, 'Perl representation');
