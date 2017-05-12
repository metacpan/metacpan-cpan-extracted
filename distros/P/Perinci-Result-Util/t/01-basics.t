#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Result::Util qw(is_env_res);
use Test::More 0.98;

subtest is_env_res => sub {
    ok(!is_env_res(undef), "not defined -> no");
    ok(!is_env_res({}), "not array -> no");
    ok(!is_env_res([1, 2, 3, 4, 5]), "too long -> no");
    ok(!is_env_res([]), "too short -> no");

    ok(!is_env_res(["x"]), "status not int 1 -> no");
    ok(!is_env_res([1.1]), "status not int 2 -> no");
    ok(!is_env_res([-1]), "status negative -> no");
    ok(!is_env_res([1000]), "status too large -> no");
    ok(!is_env_res([900]), "status too large -> no 2");
    ok(!is_env_res([90]), "status too small");

    ok(!is_env_res([200, []]), "message not string -> no");
    ok(!is_env_res([200, 200]), "message must contains letters");

    ok(!is_env_res([200, "OK", undef, []]), "resmeta not hash -> no");

    ok( is_env_res([200]), "yes 1");
    ok( is_env_res([404, "Not found"]), "yes 2");
    ok( is_env_res([200, "OK", {}]), "yes 3");
    ok( is_env_res([200, "OK", undef, undef]), "yes 4");
    ok( is_env_res([200, "OK", undef, {}]), "yes 5");
};

DONE_TESTING:
done_testing;
