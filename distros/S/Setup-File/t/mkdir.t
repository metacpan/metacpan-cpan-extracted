#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use File::chdir;
use File::Path qw(remove_tree);
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use Setup::File;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name        => "didn't exist",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::mkdir',
    args        => {path=>"dir1"},
    reset_state => sub { remove_tree "dir1" },
);

test_tx_action(
    name        => "dir already exists",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::mkdir',
    args        => {path=>"dir1"},
    reset_state => sub { remove_tree "dir1"; mkdir "dir1" },
    status      => 304,
);

test_tx_action(
    name        => "file exists",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::mkdir',
    args        => {path=>"file"},
    reset_state => sub { remove_tree "file"; write_text "file", "" },
    status      => 412,
);

subtest "symlink tests" => sub {
    plan skip_all => "symlink() not available" unless eval { symlink "",""; 1 };

    test_tx_action(
        name        => "allow_symlink=0 (the default)",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkdir',
        args        => {path=>"sym1"},
        reset_state => sub {
            remove_tree "dir1";
            mkdir "dir1"; symlink "dir1", "sym1";
        },
        status      => 412,
    );

    test_tx_action(
        name        => "allow_symlink=1",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkdir',
        args        => {path=>"sym1", allow_symlink=>1},
        reset_state => sub {
            remove_tree "sym1"; mkdir "dir1"; symlink "dir1", "sym1";
        },
        status      => 304,
    );

    test_tx_action(
        name        => "allow_symlink=1, symlink points to non-dir",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkdir',
        args        => {path=>"sym1", allow_symlink=>1},
        reset_state => sub {
            remove_tree "sym1";
            mkdir "dir1"; write_text("file", ""); symlink "file", "sym1";
        },
        status      => 412,
    );
};

# XXX test mode

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
