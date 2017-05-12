#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use Perinci::Object;

my $envres = envresmulti;
is($envres->status, 200, "Default status is 200");

subtest "all success" => sub {
    my $envres = envresmulti;
    $envres->add_result(200, "OK", {item_id=>1});
    $envres->add_result(202, "OK", {item_id=>2, note=>"blah"});
    $envres->add_result(304, "Not modified", {item_id=>3});
    my $res = $envres->as_struct;
    is($res->[0], 200, "final status");
    is_deeply($res->[3]{results}, [
        {status=>200, message=>"OK", item_id=>1},
        {status=>202, message=>"OK", item_id=>2, note=>"blah"},
        {status=>304, message=>"Not modified", item_id=>3},
    ], "final results") or diag explain $res;
};

subtest "partial success (success first)" => sub {
    my $envres = envresmulti;
    my $res;

    $envres->add_result(200, "OK", {item_id=>1});
    $res = $envres->as_struct;
    is($res->[0], 200, "status 1");
    is_deeply($res->[3]{results}, [
        {status=>200, message=>"OK", item_id=>1},
    ], "results 1") or diag explain $res;

    $envres->add_result(404, "Not found", {item_id=>2, note=>"blah"});
    $res = $envres->as_struct;
    is($res->[0], 207, "final status");
    is_deeply($res->[3]{results}, [
        {status=>200, message=>"OK", item_id=>1},
        {status=>404, message=>"Not found", item_id=>2, note=>"blah"},
    ], "final results") or diag explain $res;
};

subtest "partial success (fail first)" => sub {
    my $envres = envresmulti;
    my $res;

    $envres->add_result(500, "Failed", {item_id=>1});
    $res = $envres->as_struct;
    is($res->[0], 500, "status 1");
    is_deeply($res->[3]{results}, [
        {status=>500, message=>"Failed", item_id=>1},
    ], "results 1") or diag explain $res;

    $envres->add_result(200, "OK", {item_id=>2});
    $res = $envres->as_struct;
    is($res->[0], 207, "final status");
    is_deeply($res->[3]{results}, [
        {status=>500, message=>"Failed", item_id=>1},
        {status=>200, message=>"OK", item_id=>2},
    ], "final results") or diag explain $res;
};

subtest "all fail" => sub {
    my $envres = envresmulti;
    $envres->add_result(404, "Not found", {item_id=>1});
    $envres->add_result(500, "Failed", {item_id=>2});
    my $res = $envres->as_struct;
    is($res->[0], 500, "final status");
    is_deeply($res->[3]{results}, [
        {status=>404, message=>"Not found", item_id=>1},
        {status=>500, message=>"Failed", item_id=>2},
    ], "final results") or diag explain $res;
};

done_testing;
