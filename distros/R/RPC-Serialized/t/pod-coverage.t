#!perl -T

use Test::More 'no_plan';
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
pod_coverage_ok( 'RPC::Serialized',
    {also_private => [ qr/./, ]}
);
