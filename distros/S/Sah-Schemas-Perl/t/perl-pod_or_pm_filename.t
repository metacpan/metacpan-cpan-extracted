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
        type=>"str", coerce_rules => ['str_convert_perl_pod_or_pm_to_path']);

    is_deeply($c->([]), [], "uncoerced");
    is($c->("*"), "*", "uncoerced 2");

    is($c->("strict"), module_path(module => "strict"), "becomes module path");
    is($c->("Test::More"), module_path(module => "Test::More"), "becomes module path 2");
    is($c->("Test/More"), module_path(module => "Test::More"), "becomes module path 3");
    is($c->("Test/More.pm"), module_path(module => "Test::More"), "becomes module path 4");
    if (pod_path(module => "Rinci")) {
        is($c->("Rinci.pod"), pod_path(module => "Rinci"), "becomes pod path");
        is($c->("Rinci"), pod_path(module => "Rinci"), "becomes pod path 2");
        is($c->("Rinci.pm"), module_path(module => "Rinci"), "becomes module path");
    }

    is($c->("Test/More.pod"), "Test/More.pod", "does not become module path (.pod doesn't exist)");
    is($c->("Thingamagic"), "Thingamagic", "does not become module path (module doesn't exist)");
    is($c->("./strict"), "./strict", "does not become module path (./ prefix)");
};

done_testing;
