#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Fatal;

use Starch::Util qw(
    load_prefixed_module
);

subtest load_prefixed_module => sub{
    my $prefix = 'Starch';
    my $suffix = '::Test::LoadPrefixedModule';
    my $package = $prefix . $suffix;
    like(
        exception { load_prefixed_module( $prefix, $package ) },
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
