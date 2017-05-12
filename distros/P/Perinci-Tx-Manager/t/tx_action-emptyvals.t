#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';
use lib "$Bin/lib";

use File::chdir;
use File::Temp qw(tempdir);
use Test::More 0.98;
use Test::Perinci::Tx::Manager qw(test_tx_action);
use TestTx;

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;

test_tx_action(
    name    => 'fixed',
    tmpdir  => $tmpdir,
    f       => 'TestTx::emptyvals',
    args    => {},
    confirm => 1,
    reset_state => sub { %TestTx::vals = () },
    status  => 304,
);

test_tx_action(
    name    => 'without confirm',
    tmpdir  => $tmpdir,
    f       => 'TestTx::emptyvals',
    args    => {},
    reset_state => sub { %TestTx::vals = (a=>1) },
    status  => 331,
);

test_tx_action(
    name    => 'with confirm',
    tmpdir  => $tmpdir,
    f       => 'TestTx::emptyvals',
    args    => {},
    confirm => 1,
    reset_state => sub { %TestTx::vals = (a=>1) },
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #diag "all tests successful, deleting test data dir";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting test data dir $tmpdir";
}
