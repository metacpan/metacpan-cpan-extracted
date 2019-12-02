#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;
use Test::Needs;

use Data::Sah qw(gen_validator);

subtest "basics" => sub {
    my $v = gen_validator(
        "filesize",
        {return_type => "str+val"},
    );

    my ($res, $val);

    # valid
    ($res, $val) = @{ $v->("1k") };
    ok(!$res);
    is($val, "1024");
};

done_testing;
