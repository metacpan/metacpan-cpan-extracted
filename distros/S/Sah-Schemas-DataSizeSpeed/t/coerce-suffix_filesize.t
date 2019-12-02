#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah::Coerce qw(gen_coercer);

subtest "basics" => sub {
    my $c = gen_coercer(type=>"float", coerce_rules=>["From_str::suffix_filesize"]);

    subtest "uncoerced" => sub {
        is_deeply($c->([]), [], "uncoerced");
    };
    subtest "coerced" => sub {
        is_deeply($c->("1k"), "1024");
    };
};

done_testing;
