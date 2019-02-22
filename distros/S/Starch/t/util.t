#!/usr/bin/env perl
use 5.008001;
use strictures 2;

use Test2::V0;

use Starch::Util qw(
    load_prefixed_module
);

subtest load_prefixed_module => sub{
    my $prefix = 'Starch';
    my $suffix = '::Test::LoadPrefixedModule';
    my $package = $prefix . $suffix;
    like(
        dies { load_prefixed_module( $prefix, $package ) },
        qr{Can't locate},
        'load_prefixed_module failed on non-existing module',
    );

    eval "package $package; use Moo";

    is(
        load_prefixed_module( $prefix, $package ),
        'Starch::Test::LoadPrefixedModule',
        'load_prefixed_module on absolute package name',
    );

    is(
        load_prefixed_module( $prefix, $suffix ),
        'Starch::Test::LoadPrefixedModule',
        'load_prefixed_module on relative package name',
    );
};

done_testing;
