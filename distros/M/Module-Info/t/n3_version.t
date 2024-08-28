#!/usr/bin/perl -w

use strict;
use lib './t/lib';
use Test::More tests => 15;
use lib '.';
use Module::Info;

my $has_version_pm = eval 'use version; 1';

my $moo = Module::Info->new_from_module( 'Moo' );
my $boo = Module::Info->new_from_module( 'Boo' );
my $roo = Module::Info->new_from_module( 'Roo' );
my $moo_ver;
my $foo_ver;
my $roo_ver;

if( $has_version_pm ) {
    $moo_ver = Module::Info->new_from_module( 'Moo' );
    $foo_ver = Module::Info->new_from_module( 'Foo' );
    $moo_ver->use_version( 1 );
    $foo_ver->use_version( 1 );
}

is( $moo->use_version, 0 );
is( $moo->version, '0.12' );
is( $boo->version, '1.35', 'proper quoting in complex expression' );
is( $roo->version, '1.25', 'package NAME VERSION' );

SKIP: {
    skip 'version.pm not found', 5 unless $has_version_pm;

    is( $moo_ver->use_version, 1 );
    isa_ok( $moo_ver->version, 'version' );
    is( $moo_ver->version, '0.120' );

    isa_ok( $foo_ver->version, 'version' );
    is( $foo_ver->version, '7.254' );
}

SKIP: {
    skip 'version.pm found, can not test', 6 if $has_version_pm;

    my $dummy = Module::Info->new_from_module( 'Moo' );

    is( $dummy->use_version, 0 );
    # should succeed
    eval {
        $dummy->use_version( 0 );
    };
    ok( !$@ );
    is( $dummy->use_version, 0 );

    # should fail
    eval {
        $dummy->use_version( 1 );
    };
    ok( $@ );
    ok( $@ =~ /^Can not use 'version.pm' as requested/ );
    is( $dummy->use_version, 0 );
}
