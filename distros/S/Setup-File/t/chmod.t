#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use File::chdir;
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use Setup::File;
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name        => "unfixable (didn't exist)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chmod',
    args        => {path=>"p", mode=>0755},
    reset_state => sub { remove_tree "p" },
    status      => 412,
);

test_tx_action(
    name        => "fixed (mode already correct)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chmod',
    args        => {path=>"p", mode=>0775},
    reset_state => sub { remove_tree "p"; mkdir "p"; chmod 0775, "p" },
    status      => 304,
);

test_tx_action(
    name        => "fixable",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chmod',
    args        => {path=>"p", mode=>0775},
    reset_state => sub { remove_tree "p"; mkdir "p"; chmod 0755, "p" },
);

test_tx_action(
    name        => "fixable (symbolic mode)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chmod',
    args        => {path=>"p", mode=>"go+w"},
    reset_state => sub { remove_tree "p"; mkdir "p"; chmod 0755, "p" },
);

test_tx_action(
    name        => "mode changed before undo (w/o confirm)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chmod',
    args        => {path=>"p", mode=>0775},
    reset_state => sub { remove_tree "p"; mkdir "p"; chmod 0755, "p" },
    before_undo => sub { chmod 0777, "p" },
    undo_status => 331,
);

test_tx_action(
    name        => "mode changed before undo (w/ confirm)",
    tmpdir      => $tmpdir,
    f           => 'Setup::File::chmod',
    args        => {path=>"p", mode=>0775},
    confirm     => 1,
    reset_state => sub { remove_tree "p"; mkdir "p"; chmod 0755, "p" },
    before_undo => sub { chmod 0777, "p" },
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
