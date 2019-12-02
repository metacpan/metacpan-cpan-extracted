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
        type=>"str", coerce_rules => ['From_str::convert_perl_pod_to_path']);

    is_deeply($c->([]), [], "uncoerced");
    is($c->("*"), "*", "uncoerced 2");

    is($c->("Test::More"), "Test::More", "does not become module path 2");
    is($c->("Test/More"), "Test/More", "does not become module path 3");
    is($c->("Test/More.pm"), "Test/More.pm", "does not become module path 4");

    if (pod_path(module => "Rinci")) {
        is($c->("Rinci.pod"), pod_path(module => "Rinci.pod"), "becomes pod path");
        is($c->("./Rinci.pod"), "./Rinci.pod", "does not become pod path (./ prefix)");
    }
    is($c->("Test/More.pod"), "Test/More.pod", "does not become pod path (.pod doesn't exist)");
    is($c->("./strict"), "./strict", "does not become pod path (./ prefix) 2");
};

done_testing;
