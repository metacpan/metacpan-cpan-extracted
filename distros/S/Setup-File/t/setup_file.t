#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurper qw(read_text write_text);
use File::Temp qw(tempdir);
use Setup::File;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name          => "should_exist=undef, doesn't exist -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_file",
    args          => {path=>"p"},
    reset_state   => sub {
        remove_tree "p";
    },
    status        => 304,
);
test_tx_action(
    name          => "should_exist=undef, exists -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_file",
    args          => {path=>"p"},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "";
    },
    status        => 304,
);

test_tx_action(
    name          => "should_exist=0, doesn't exist -> noop",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_file",
    args          => {path=>"p", should_exist=>0},
    reset_state   => sub {
        remove_tree "p";
    },
    status        => 304,
);
test_tx_action(
    name          => "should_exist=0, exists -> delete",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_file",
    args          => {path=>"p", should_exist=>0},
    reset_state   => sub {
        remove_tree "p";
        write_text "p", "";
    },
    after_do      => sub {
        ok(!(-f "p"), "file deleted");
    },
    after_undo    => sub {
        ok((-f "p"), "file restored");
    },
);

test_tx_action(
    name          => "create",
    tmpdir        => $tmpdir,
    f             => "Setup::File::setup_file",
    args          => {path=>"p", should_exist=>1},
    reset_state   => sub {
        remove_tree "p";
    },
    after_do      => sub {
        ok((-f "p"), "file created");
    },
    after_undo    => sub {
        ok(!(-f "p"), "file re-deleted");
    },
);

for my $existed (0, 1) {
    test_tx_action(
        name          => ($existed ? "replace":"create").", content",
        tmpdir        => $tmpdir,
        f             => "Setup::File::setup_file",
        args          => {path=>"p", should_exist=>1, content=>"bar"},
        reset_state   => sub {
            remove_tree "p";
            write_text("p", "foo") if $existed;
        },
        after_do      => sub {
            ok((-f "p"), "file created");
            is(read_text("p"), "bar", "content set");
        },
        after_undo    => sub {
            if ($existed) {
                ok((-f "p"), "file still exists");
                is(read_text("p"), "foo", "old content restored");
            } else {
                ok(!(-f "p"), "file re-deleted");
            }
        },
    );

    # content_md5, gen_content_func, check_content_func have been tested with
    # mkfile.

    test_tx_action(
        name          => ($existed ? "replace":"create").", mode",
        tmpdir        => $tmpdir,
        f             => "Setup::File::setup_file",
        args          => {path=>"p", should_exist=>1, content=>"bar",
                          mode=>0664},
        reset_state   => sub {
            remove_tree "p";
            do { write_text("p", "foo"); chmod 0644, "p" } if $existed;
        },
        after_do      => sub {
            ok((-f "p"), "file created");
            is(read_text("p"), "bar", "content set");
            my @st = stat "p";
            is($st[2] & 07777, 0664, "mode set");
        },
        after_undo    => sub {
            if ($existed) {
                ok((-f "p"), "file still exists");
                is(read_text("p"), "foo", "old content restored");
                my @st = stat "p";
                is($st[2] & 07777, 0644, "old mode restored");
            } else {
                ok(!(-f "p"), "file re-deleted");
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
