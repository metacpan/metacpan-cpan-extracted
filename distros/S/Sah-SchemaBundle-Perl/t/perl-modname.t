#!perl

use 5.010001;
use strict;
use warnings;

use Test::More 0.98;
use Test::Needs;

subtest "coercion" => sub {
    test_needs 'Data::Sah::Coerce';

    my $c = Data::Sah::Coerce::gen_coercer(
        type=>"str", coerce_rules => ['From_str::normalize_perl_modname']);

    is_deeply($c->([]), [], "uncoerced");
    is($c->("*"), "*", "uncoerced 2");
    is($c->("Foo"), "Foo");
    is($c->("Foo-Bar")   , "Foo::Bar");
    is($c->("Foo::Bar")  , "Foo::Bar");
    is($c->("Foo:Bar")   , "Foo::Bar");
    is($c->("Foo/Bar")   , "Foo::Bar");
    is($c->("Foo.Bar")   , "Foo::Bar");
    is($c->("Foo/Bar.pm"), "Foo::Bar");
};

done_testing;
