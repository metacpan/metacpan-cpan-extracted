#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use Crypt::Password::Util qw(looks_like_crypt);
use File::chdir;
use File::Path qw(remove_tree);
use File::Copy::Recursive qw(rcopy);
use File::Temp qw(tempdir);
use Setup::Unix::User;
use Test::More 0.96;
use Test::Perinci::Tx::Manager qw(test_tx_action);
use Unix::Passwd::File qw(get_user get_group);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
my %ca = (etc_dir => "$tmpdir/etc");

test_tx_action(
    name        => "fixed: user already exists",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"u1"},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    status      => 304,
);

test_tx_action(
    name        => "unfixable: user already exists with different uid",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"u1", uid=>1001},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    status      => 412,
);

test_tx_action(
    name        => "add",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo"},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    after_do    => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 200, "user exists");
        is($res->[2]{uid}, 1002, "uid");
    },
    after_undo  => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 404, "user doesn't exist");
    },
);

test_tx_action(
    name        => "gid argument, add non-unique gid is ok",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo", gid=>1001},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    after_do    => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 200, "user exists");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 200, "group exists");
        is($res->[2]{gid}, 1001, "gid");
    },
    after_undo  => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 404, "user doesn't exist");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 404, "group doesn't exist");
    },
);

test_tx_action(
    name        => "uid argument, add non-unique uid is ok",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo", uid=>1001},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    after_do    => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 200, "user exists");
        is($res->[2]{uid}, 1001, "uid");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 200, "group exists");
    },
    after_undo  => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 404, "user doesn't exist");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 404, "group doesn't exist");
    },
);

test_tx_action(
    name        => "min_gid/max_gid argument (available)",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo", min_gid=>2000, max_gid=>2001},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    after_do    => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 200, "user exists");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 200, "group exists");
        is($res->[2]{gid}, 2000, "gid");
    },
    after_undo  => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 404, "user doesn't exist");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 404, "group doesn't exist");
    },
);

test_tx_action(
    name        => "min_gid/max_gid argument (unavailable)",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo", min_gid=>1000, max_gid=>1001},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    status => 532,
);

test_tx_action(
    name        => "min_uid/max_uid argument (available)",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo", min_uid=>2000, max_uid=>2001},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    after_do    => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 200, "user exists");
        is($res->[2]{uid}, 2000, "uid");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 200, "group exists");
    },
    after_undo  => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 404, "user doesn't exist");
        $res = get_group(%ca, group=>"foo");
        is($res->[0], 404, "group doesn't exist");
    },
);

test_tx_action(
    name        => "min_uid/max_uid argument (unavailable)",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo", min_uid=>1000, max_uid=>1001},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    status => 532,
);

test_tx_action(
    name        => "pass, gecos, shell, home, group arguments",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::User::adduser",
    args        => {%ca, user=>"foo", group=>"u1", pass=>"123", gecos=>"bar",
                    home=>"/home2/foo", shell=>"/bin/baz"},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    after_do    => sub {
        my $res = get_user(%ca, user=>"foo");
        #diag explain $res;
        is($res->[0], 200, "user exists");
        is($res->[2]{gid}, "1000", "gid");
        is($res->[2]{pass}, "x", "pass");
        ok(looks_like_crypt($res->[2]{encpass}), "encpass");
        is($res->[2]{gecos}, "bar", "gid");
        is($res->[2]{home}, "/home2/foo", "home");
        is($res->[2]{shell}, "/bin/baz", "shell");
    },
    after_undo  => sub {
        my $res = get_user(%ca, user=>"foo");
        is($res->[0], 404, "user doesn't exist");
    },
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #note "all tests successful, deleting temp files";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tempdir $tmpdir";
}
