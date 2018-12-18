#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);
#use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $v = gen_validator(
            ["domain::name"],
            {return_type=>"bool"},
        );
    my $v2 = gen_validator(
            ["domain::name"],
            {return_type=>"str+val"},
        );

    ok(!$v->("foo"), "minimum two words");
    ok( $v->("foo.bar"));
    ok( $v->("Foo.BAR"));
    ok( $v->("foo.bar.baz"));
    ok( $v->("foo.bar.baz.qux"));

    ok(!$v->("-foo.com"), "hyphen not allowed at the beginning");
    ok(!$v->("foo-.com"), "hyphen not allowed at the end");
    ok( $v->("fo-o.com"));
    ok( $v->("fo--o.com"));

    ok(!$v->("fo_o.com"), "invalid character _");

    is_deeply($v2->("Foo.com"), ["", "foo.com"], "normalized to lowercase");
};

done_testing;
