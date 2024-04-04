#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Module::Path::More qw(module_path pod_path);

subtest "coercion" => sub {
    test_needs 'Data::Sah::Coerce';

    my $c = Data::Sah::Coerce::gen_coercer(
        type=>"str", coerce_rules => ['From_str::convert_perl_pm_to_path']);

    is_deeply($c->([]), [], "uncoerced");
    is($c->("*"), "*", "uncoerced 2");

    is($c->("Test::More"), module_path(module => "Test::More"), "becomes module path 2");
    is($c->("Test/More"), module_path(module => "Test::More"), "becomes module path 3");
    is($c->("Test/More.pm"), module_path(module => "Test::More"), "becomes module path 4");

    if (pod_path(module => "Rinci")) {
        is($c->("Rinci.pod"), "Rinci.pod", "does not become pod path");
    }
    is($c->("Test/More.pod"), "Test/More.pod", "does not become module path (.pod doesn't exist)");
    is($c->("Thingamagic"), "Thingamagic", "does not become module path (module doesn't exist)");
    is($c->("./strict"), "./strict", "does not become module path (./ prefix)");
};

done_testing;
