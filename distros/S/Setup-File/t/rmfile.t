#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use Digest::MD5 qw(md5_hex);
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
    name        => "fixed (file doesn't exist)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p"},
    reset_state => sub { remove_tree "p" },
    status      => 304,
);

test_tx_action(
    name        => "unfixable: non-file",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p"},
    reset_state => sub { remove_tree "p"; write_text("p", "") },
);

test_tx_action(
    name        => "fixable",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p"},
    reset_state => sub { remove_tree "p"; write_text "p", "" },
);

test_tx_action(
    name        => "orig_content",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p", orig_content=>"foo"},
    reset_state => sub {
        remove_tree "p";
        write_text("p", "foo");
    },
);

test_tx_action(
    name        => "content changed (orig_content), w/o confirm",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p", orig_content=>"foo"},
    reset_state => sub {
        remove_tree "p";
        write_text("p", "bar");
    },
    status      => 331,
);

test_tx_action(
    name        => "content changed (orig_content), w/ confirm",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p", orig_content=>"foo"},
    confirm     => 1,
    reset_state => sub {
        remove_tree "p";
        write_text("p", "bar");
    },
);

test_tx_action(
    name        => "orig_content_md5",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p", orig_content_md5=>md5_hex("foo")},
    reset_state => sub {
        remove_tree "p";
        write_text("p", "foo");
    },
);

test_tx_action(
    name        => "content changed (orig_content), w/o confirm",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p", orig_content_md5=>md5_hex("foo")},
    reset_state => sub {
        remove_tree "p";
        write_text("p", "bar");
    },
    status      => 331,
);

test_tx_action(
    name        => "content changed (orig_content_md5), w/ confirm",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::rmfile',
    args        => {path=>"p", orig_content_md5=>md5_hex("foo")},
    confirm     => 1,
    reset_state => sub {
        remove_tree "p";
        write_text("p", "bar");
    },
);

subtest "symlink tests" => sub {
    plan skip_all => "symlink() not available"
        unless eval { symlink "",""; 1 };

    test_tx_action(
        name        => "allow_symlink=0 (the default)",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::rmfile',
        args        => {path=>"s"},
        reset_state => sub {
            remove_tree "p"; unlink "s";
            write_text("p", ""); symlink "p", "s";
        },
        status      => 412,
    );

    test_tx_action(
        name        => "allow_symlink=1",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::rmfile',
        args        => {path=>"s", allow_symlink=>1},
        reset_state => sub {
            remove_tree "p"; unlink "s";
            write_text("p", ""); symlink "p", "s";
        },
    );

    test_tx_action(
        name        => "allow_symlink=1, symlink points to non-file",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::rmfile',
        args        => {path=>"s", allow_symlink=>1},
        reset_state => sub {
            remove_tree "p"; unlink "s";
            mkdir "p"; symlink "p", "s";
        },
        status      => 412,
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
