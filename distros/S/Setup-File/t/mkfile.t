#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";
use Log::Any::IfLOG '$log';

use Digest::MD5 qw(md5_hex);
use File::chdir;
use File::Path qw(remove_tree);
use File::Slurp::Tiny qw(read_file write_file);
use File::Temp qw(tempdir);
use Setup::File;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name        => "unfixable: non-file",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::mkfile',
    args        => {path=>"p"},
    reset_state => sub { remove_tree "p"; mkdir "p" },
    status      => 412,
);

test_tx_action(
    name        => "fixed: file exists",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::mkfile',
    args        => {path=>"p"},
    reset_state => sub { remove_tree "p"; write_file "p", "" },
    status      => 304,
);
test_tx_action(
    name        => "fixed: file exists (content doesn't matter)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::mkfile',
    args        => {path=>"p"},
    reset_state => sub { remove_tree "p"; write_file "p", "a" },
    status      => 304,
);

test_tx_action(
    name        => "fixable: file didn't exist",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::mkfile',
    args        => {path=>"p"},
    reset_state => sub { remove_tree "p" },
    after_do    => sub {
        ok((-f "p"), "p is a file");
        is(scalar(read_file "p"), "", "p's content is empty");
    },
);

sub _check_ct {
    my $ctr = shift;
    $log->errorf("TMP:ct=%s=", $$ctr);
    $$ctr eq 'bar';
}

sub _gen_ct {
    my $ctr = shift;
    "bar";
}

for my $existed (0, 1) {
    test_tx_action(
        name        => "fixable: ".
            ($existed ? "file existed":"file didn't exist").", content",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkfile',
        args        => {path=>"p", content=>"bar"},
        reset_state => sub {
            remove_tree "p";
            write_file("p", "foo") if $existed;
        },
        after_do    => sub {
            ok((-f "p"), "p is a file");
            is(scalar(read_file "p"), "bar", "p's content is fixed");
        },
        after_undo  => sub {
            if ($existed) {
                ok((-f "p"), "p is a file");
                is(scalar(read_file "p"), "foo", "p's old content is restored");
            } else {
                ok(!(-f "p"), "p does not exist");
            }
        },
    );

    test_tx_action(
        name        => "fixable: ".
            ($existed ? "file existed":"file didn't exist").", content_md5",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkfile',
        args        => {path=>"p", content_md5=>md5_hex("")},
        reset_state => sub {
            remove_tree "p";
            write_file("p", "foo") if $existed;
        },
        after_do    => sub {
            ok((-f "p"), "p is a file");
            is(scalar(read_file "p"), "", "p's content is fixed");
        },
        after_undo  => sub {
            if ($existed) {
                ok((-f "p"), "p is a file");
                is(scalar(read_file "p"), "foo", "p's old content is restored");
            } else {
                ok(!(-f "p"), "p does not exist");
            }
        },
    );

    test_tx_action(
        name        => "fixable: ".
            ($existed ? "file existed":"file didn't exist").
                ", check_content_func + gen_content_func",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkfile',
        args        => {path=>"p",
                        check_content_func=>"main::_check_ct",
                        gen_content_func=>"main::_gen_ct"},
        reset_state => sub {
            remove_tree "p";
            write_file("p", "foo") if $existed;
        },
        after_do    => sub {
            ok((-f "p"), "p is a file");
            is(scalar(read_file "p"), "bar", "p's content is fixed");
        },
        after_undo  => sub {
            if ($existed) {
                ok((-f "p"), "p is a file");
                is(scalar(read_file "p"), "foo", "p's old content is restored");
            } else {
                ok(!(-f "p"), "p does not exist");
            }
        },
    );
}

subtest "symlink tests" => sub {
    plan skip_all => "symlink() not available" unless eval { symlink "",""; 1 };

    test_tx_action(
        name        => "allow_symlink=0 (the default)",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkfile',
        args        => {path=>"s"},
        reset_state => sub {
            remove_tree "p";
            write_file "p", ""; symlink "p", "s";
        },
        status      => 412,
    );

    test_tx_action(
        name        => "allow_symlink=1",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkfile',
        args        => {path=>"s", allow_symlink=>1},
        reset_state => sub {
            remove_tree "p";
            write_file "p", ""; symlink "p", "s";
        },
        status      => 304,
    );

    test_tx_action(
        name        => "allow_symlink=1, symlink points to non-file",
        tmpdir      => $tmpdir,
        f           => 'Setup::File::mkfile',
        args        => {path=>"s", allow_symlink=>1},
        reset_state => sub {
            remove_tree "p";
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
