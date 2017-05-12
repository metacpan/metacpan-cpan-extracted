#!perl

use Test::More 0.98;
use Test::Needs;

plan skip_all => 'Tests incompatible with Test::More 1.001014'
    if $Test::More::VERSION == 1.001014;


use_ok('Test::Dependencies');
use_ok('Test::Dependencies::Light');

subtest "Heavy Loading" => sub {
    test_needs 'B::PerlReq', 'PerlReq::Utils';
    use_ok('Test::Dependencies::Heavy');
};

done_testing;
