#!perl

use 5.010;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Test::More 0.98;
require "testlib.pl";

use vars qw($tmp_dir);

setup();

my %ca = (
    min_new_uid   => 2000,
    min_new_gid   => 3000,
    new_pass      => "123",
    new_gecos     => "user 3",
    new_home      => "$tmp_dir/home",
    new_shell     => "/bin/shell",
    skel_dir      => "$tmp_dir/skel",
);

goto L2;

test_setup_unix_user(
    name          => "create with create_home=0",
    args          => {%ca, user=>"u3", create_home=>0},
    after_do      => {
        uid=>2000, gid=>3000,
        gecos=>"user 3",
        home=>"$tmp_dir/home",
        shell=>"/bin/shell",
        extra => sub {
            ok(!(-d "$tmp_dir/home"), "home not created");
        }
    },
    after_undo    => {
        exists=>0,
        extra => sub {
            ok(!(-d "$tmp_dir/home"), "home doesn't exist");
        }
    },
);

test_setup_unix_user(
    name          => "create with create_home=1 + use_skel=0",
    args          => {%ca, user=>"u3", use_skel=>0},
    after_do      => {
        uid=>2000, gid=>3000,
        extra => sub {
            ok( (-d "$tmp_dir/home"), "home created");
        }
    },
    after_undo    => {
        exists=>0,
        extra => sub {
            ok(!(-d "$tmp_dir/home"), "home removed");
        }
    },
);

test_setup_unix_user(
    name          => "create",
    args          => {%ca, user=>"u3"},
    after_do      => {
        uid=>2000, gid=>3000,
        extra => sub {
            ok( (-d "$tmp_dir/home"), "home created");
            ok( (-f "$tmp_dir/home/.dir1/.file1"), "skeleton file created");
        }
    },
    after_undo    => {
        exists=>0,
        extra => sub {
            ok(!(-d "$tmp_dir/home"), "home removed");
        }
    },
);

test_setup_unix_user(
    name          => "already exists + home !exists + create_home=0 -> noop",
    args          => {%ca, user=>"u1", create_home=>0},
    status        => 304,
);

test_setup_unix_user(
    name          => "already exists -> only create home",
    args          => {%ca, user=>"u1"},
    after_do      => {
        extra => sub {
            ok( (-d "$tmp_dir/u1"), "home created");
            ok( (-f "$tmp_dir/u1/.dir1/.file1"), "skeleton file created");
        }
    },
    after_undo    => {
        extra => sub {
            ok(!(-d "$tmp_dir/u1"), "home removed");
        }
    },
);

L2:
test_setup_unix_user(
    name          => "already exists -> only fix memberships",
    args          => {%ca, user=>"u1", create_home=>0,
                      member_of=>[qw/bin/], not_member_of=>[qw/u2/]},
    after_do      => {
        member_of     => [qw/u1 bin/],
        not_member_of => [qw/u2/],
        extra => sub {
            ok(!(-d "$tmp_dir/u1"), "home not created");
        }
    },
    after_undo    => {
        member_of     => [qw/u1 u2/],
        not_member_of => [qw/bin/],
        extra => sub {
            ok(!(-d "$tmp_dir/u1"), "home not exists");
        }
    },
);

DONE_TESTING:
teardown();
