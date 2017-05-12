#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Test::More 0.96;
require "testlib.pl";

setup();

test_setup_unix_group(
    name       => "default",
    args       => {group=>"g1"},
    after_do   => {gid=>1001},
    after_undo => {exists=>0},
);
test_setup_unix_group(
    name       => "should_already_exist=1",
    args       => {group=>"g1", should_already_exist=>1},
    status     => 412,
);
test_setup_unix_group(
    name       => "already created -> noop",
    args       => {group=>"u1"},
    status     => 304,
);
test_setup_unix_group(
    name       => "already created + should_already_exist=1 -> noop",
    args       => {group=>"u1", should_already_exist=>1},
    status     => 304,
);

test_setup_unix_group(
    name       => "should_exist=0, doesn't exist -> noop",
    args       => {group=>"u1", should_exist=>0},
    after_do   => {exists=>0},
    after_undo => {gid=>1000},
);
test_setup_unix_group(
    name       => "should_exist=0, doesn't exist -> noop",
    args       => {group=>"g1", should_exist=>0},
    after_do   => {exists=>0},
    after_undo => {exists=>0},
    status     => 304,
);

test_setup_unix_group(
    name       => "create with new_gid (success)",
    args       => {group=>"g1", new_gid=>2000},
    after_do   => {gid=>2000},
    after_undo => {exists=>0},
);

test_setup_unix_group(
    name       => "create with min_new_gid & max_new_gid (success)",
    args       => {group=>"g2", min_new_gid=>1000, max_new_gid=>1002},
    after_do   => {gid=>1001},
    after_undo => {exists=>0},
);
test_setup_unix_group(
    name       => "create with min_new_gid & max_new_gid (unavailable)",
    args       => {group=>"g3", min_new_gid=>1000, max_new_gid=>1000},
    status     => 532,
);

DONE_TESTING:
teardown();
