#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use File::chdir;
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Lchown;
use Setup::File;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

plan skip_all => "This test requires running as superuser" if $>;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name        => "unfixable (didn't exist)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>"root", group=>"root"},
    reset_state => sub { remove_tree "p" },
    status      => 412,
);

test_tx_action(
    name        => "fixed (owner and group already correct)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>"root", group=>"root"},
    reset_state => sub {
        remove_tree "p";
        mkdir "p"; chown 0, 0, "p";
    },
    status      => 304,
);

test_tx_action(
    name        => "fixable (owner only)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>"root", group=>"root"},
    reset_state => sub {
        remove_tree "p";
        mkdir "p"; chown 1, 0, "p";
    },
);

test_tx_action(
    name        => "fixable (group only)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>"root", group=>"root"},
    reset_state => sub {
        remove_tree "p";
        mkdir "p"; chown 0, 1, "p";
    },
);

test_tx_action(
    name        => "fixable (owner & group)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>"root", group=>"root"},
    reset_state => sub {
        remove_tree "p";
        mkdir "p"; chown 1, 1, "p";
    },
);

test_tx_action(
    name        => "fixable (owner & group, numeric)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>3, group=>4},
    reset_state => sub {
        remove_tree "p";
        mkdir "p"; chown 0, 0, "p";
    },
);

test_tx_action(
    name        => "owner changed before undo (w/o confirm)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>3},
    reset_state => sub { remove_tree "p"; mkdir "p"; chown 0, 0, "p" },
    before_undo => sub { chown 4, -1, "p" },
    undo_status => 331,
);

test_tx_action(
    name        => "owner changed before undo (w/ confirm)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chown',
    args        => {path=>"p", owner=>3},
    confirm     => 1,
    reset_state => sub { remove_tree "p"; mkdir "p"; chown 0, 0, "p" },
    before_undo => sub { chown 4, -1, "p" },
);

subtest "symlink tests" => sub {
    plan skip_all => "symlink() not available" unless eval { symlink "",""; 1 };

    test_tx_action(
        name        => "follow_symlink=0 (the default)",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::chown',
        args        => {path=>"s", owner=>4, group=>5},
        reset_state => sub {
            remove_tree "p";
            mkdir "p"; chown 0, 1, "p";
            symlink "p", "s"; lchown 2, 3, "s";
        },
        after_do    => sub {
            my @stp =  stat("p");
            my @sts = lstat("s");
            is($stp[4], 0, "p's uid is 0 (unchanged)");
            is($stp[5], 1, "p's gid is 1 (unchanged)");
            is($sts[4], 4, "s's uid is 4 (changed)");
            is($sts[5], 5, "s's gid is 5 (changed)");
        },
    );

    test_tx_action(
        name        => "follow_symlink=1",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::chown',
        args        => {path=>"s", owner=>4, group=>5, follow_symlink=>1},
        reset_state => sub {
            remove_tree "p";
            mkdir "p"; chown 0, 1, "p";
            symlink "p", "s"; lchown 2, 3, "s";
        },
        after_do    => sub {
            my @stp =  stat("p");
            my @sts = lstat("s");
            is($stp[4], 4, "p's uid is 0 (changed)");
            is($stp[5], 5, "p's gid is 1 (changed)");
            is($sts[4], 2, "s's uid is 4 (unchanged)");
            is($sts[5], 3, "s's gid is 5 (unchanged)");
        },
    );
};

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
