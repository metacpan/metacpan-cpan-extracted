#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use File::chdir;
use File::Path qw(remove_tree);
use File::Copy::Recursive qw(rcopy);
use File::Temp qw(tempdir);
use Setup::Unix::Group;
use Test::More 0.96;
use Test::Perinci::Tx::Manager qw(test_tx_action);
use Unix::Passwd::File qw(get_group group_exists);

my $tmpdir = tempdir(CLEANUP=>1);
$CWD = $tmpdir;
my %ca = (etc_dir => "$tmpdir/etc");

test_tx_action(
    name        => "fixed: group already does not exist",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::Group::delgroup",
    args        => {etc_dir=>"$tmpdir/etc", group=>"foo"},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    status      => 304,
);

test_tx_action(
    name        => "fixable: group exists",
    tmpdir      => $tmpdir,
    f           => "Setup::Unix::Group::delgroup",
    args        => {etc_dir=>"$tmpdir/etc", group=>"u1"},
    reset_state => sub {
        remove_tree "etc";
        rcopy "$Bin/data/simple", "etc";
    },
    after_do    => sub {
        ok(!group_exists(%ca, group=>"u1"), "group u1 is removed");
    },
    after_undo  => sub {
        ok( group_exists(%ca, group=>"u1"), "group u1 is restored");
    },
);

DONE_TESTING:
done_testing();
if (Test::More->builder->is_passing) {
    #note "all tests successful, deleting temp files";
    $CWD = "/";
} else {
    diag "there are failing tests, not deleting tempdir $tmpdir";
}
