#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Data::Sah qw(gen_validator);
use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $v = gen_validator(
        ["url"],
        {return_type=>"bool"},
    );

    ok($v->("http://localhost"));
    ok(!$v->(""));

    # god, so permissive
    #ok(!$v->("*"));
};

done_testing;
