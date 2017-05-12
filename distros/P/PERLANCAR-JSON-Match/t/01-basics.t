#!perl

use 5.010;
use strict;
use warnings;

use PERLANCAR::JSON::Match qw(match_json);

#use Test::Exception;
use Test::More 0.98;

ok(match_json(q(null)), "scalar (null)");

ok(match_json(q(2)), "scalar (num)");

ok(match_json(q(true)), "scalar (bool, true)");

ok(match_json(q(false)), "scalar (bool, false)");

ok(match_json(q([null,1,-2,"3","four"])),
   "simple array");

ok(match_json(q({"a":1,"b":2})),
   "simple hash");

ok(match_json(q( [null,"", "a\nb c" ,2 , -3, 4.5, [ ], [ 1, "a" , [] ], { }, { "0":null ,"1":1, "b" :"b" , "c": [],"d" : {} }] )),
   "more comprehensive test (whitespaces)");

ok(!match_json(q([)), "invalid 1");
ok(!match_json(q(})), "invalid 2");
ok(!match_json(q(nul)), "invalid 3");

# XXX test trailing comma

DONE_TESTING:
done_testing;
