#!/usr/bin/perl -w

use strict;
use lib './t/lib';
use Test::More tests => 7;
use lib '.';
use Module::Info;

my $moo = Module::Info->new_from_module( 'Moo' );

is( $moo->version, '0.12' );
is( $moo->safe, 0 );

my $safe_moo = Module::Info->new_from_module( 'Moo' );
$safe_moo->safe(1);

is( $moo->safe, 0, 'safe attribute is per-object' );

is( $safe_moo->safe, 1 );

eval {
    $safe_moo->version;
};
isnt( $@, undef, '$Moo::VERSION is unsafe' );

my $safe_foo = Module::Info->new_from_module( 'Foo' );
$safe_foo->safe(1);

eval {
    is( $safe_foo->version, '7.254' );
};
is( $@, '', '$Foo::VERSION is safe' );
