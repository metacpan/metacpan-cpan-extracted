#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";
use Log::Any::IfLOG '$log';

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurp::Tiny qw(write_file);
use File::Temp qw(tempdir);
use Setup::File;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name          => "should_exist=undef, doesn't exist -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_dir",
    args          => {path=>"p"},
    reset_state   => sub {
        remove_tree "p";
    },
    status        => 304,
);
test_tx_action(
    name          => "should_exist=undef, exists -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_dir",
    args          => {path=>"p"},
    reset_state   => sub {
        remove_tree "p";
        mkdir "p";
    },
    status        => 304,
);

test_tx_action(
    name          => "should_exist=0, doesn't exist -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_dir",
    args          => {path=>"p", should_exist=>0},
    reset_state   => sub {
        remove_tree "p";
    },
    status        => 304,
);
test_tx_action(
    name          => "should_exist=0, exists -> delete",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_dir",
    args          => {path=>"p", should_exist=>0},
    reset_state   => sub {
        remove_tree "p";
        mkdir "p";
    },
    after_do      => sub {
        ok(!(-d "p"), "dir deleted");
    },
    after_undo    => sub {
        ok((-d "p"), "dir restored");
    },
);

test_tx_action(
    name          => "create",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_dir",
    args          => {path=>"p", should_exist=>1},
    reset_state   => sub {
        remove_tree "p";
    },
    after_do      => sub {
        ok((-d "p"), "dir created");
    },
    after_undo    => sub {
        ok(!(-d "p"), "dir re-deleted");
    },
);

for my $existed (0, 1) {
    test_tx_action(
        name          => ($existed ? "replace":"create").", mode",
        tmpdir        => $tmpdir,
        f             => "Setup::File::setup_dir",
        args          => {path=>"p", should_exist=>1, mode=>0775},
        reset_state   => sub {
            remove_tree "p";
            do { mkdir "p"; chmod 0755, "p" } if $existed;
        },
        after_do      => sub {
            ok((-d "p"), "dir created");
            my @st = stat "p";
            is($st[2] & 07777, 0775, "mode set");
        },
        after_undo    => sub {
            if ($existed) {
                ok((-d "p"), "dir still exists");
                my @st = stat "p";
                is($st[2] & 07777, 0755, "old mode restored");
            } else {
                ok(!(-d "p"), "dir re-deleted");
            }
        },
    );
}

# XXX test owner, group
# XXX test replace_dir
# XXX test replace_symlink
# XXX test allow_symlink

# XXX test change state before undo: content

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
