#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.96;

use File::chdir;
use File::Slurp::Tiny qw(write_file);
use File::Temp qw(tempdir);
use Setup::File::Symlink;
use Test::Perinci::Tx::Manager qw(test_tx_action);

plan skip_all => "symlink() not available"
    unless eval { symlink "", ""; 1 };

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name   => "fixable",
    tmpdir => $tmpdir,
    reset_state => sub {
        unlink "$tmpdir/s";
        symlink "x", "$tmpdir/s";
    },
    f      => 'Setup::File::Symlink::rmsym',
    args   => {path=>"$tmpdir/s"},
);

test_tx_action(
    name   => "fixed",
    tmpdir => $tmpdir,
    reset_state => sub {
        unlink "$tmpdir/s";
    },
    f      => 'Setup::File::Symlink::rmsym',
    args   => {path=>"$tmpdir/s"},
    status => 304,
);

test_tx_action(
    name   => "unfixable: target does not match",
    tmpdir => $tmpdir,
    reset_state => sub {
        unlink "$tmpdir/s";
        symlink "x", "$tmpdir/s";
    },
    f      => 'Setup::File::Symlink::rmsym',
    args   => {path=>"$tmpdir/s", target=>"y"},
    status => 412,
);

test_tx_action(
    name   => "unfixable: path not symlink",
    tmpdir => $tmpdir,
    reset_state => sub {
        unlink "$tmpdir/s";
        write_file("$tmpdir/s", "$tmpdir/s");
    },
    f      => 'Setup::File::Symlink::rmsym',
    args   => {path=>"$tmpdir/s"},
    status => 412,
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
