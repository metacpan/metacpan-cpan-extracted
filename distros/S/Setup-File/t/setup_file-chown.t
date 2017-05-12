#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurp::Tiny qw(read_file write_file);
use File::Temp qw(tempdir);
use Setup::File;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

plan skip_all => "must run as root to test changing ownership/group" if $>;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

for my $existed (0, 1) {
    test_tx_action(
        name          => ($existed ? "replace":"create").", owner+group",
        tmpdir        => $tmpdir,
        f             => "Setup::File::setup_file",
        args          => {path=>"p", should_exist=>1, content=>"bar",
                          owner=>3, group=>4},
        reset_state   => sub {
            remove_tree "p";
            do { write_file("p", "foo"); chown 1, 2, "p" } if $existed;
        },
        after_do      => sub {
            ok((-f "p"), "file created");
            is(scalar(read_file "p"), "bar", "content set");
            my @st = stat "p";
            is($st[4], 3, "owner set");
            is($st[5], 4, "group set");
        },
        after_undo    => sub {
            if ($existed) {
                ok((-f "p"), "file still exists");
                is(scalar(read_file "p"), "foo", "old content restored");
                my @st = stat "p";
                is($st[4], 1, "old owner restored");
                is($st[5], 2, "old group restored");
            } else {
                ok(!(-f "p"), "file re-deleted");
            }
        },
    );
}

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
