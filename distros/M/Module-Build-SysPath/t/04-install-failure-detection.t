#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use File::Spec;
use FindBin qw($Bin);

my $exec_probe = sub {
    local $ENV{SYSPATH_TEST_FAIL_ORIGINAL_INSTALL} = 1;
    open(STDERR, '>&', STDOUT) or die $!;
    exec $^X, File::Spec->catfile($Bin, '01_Module-Build-SysPath.t');
    die "exec: $!";
};
my $pid = open(my $output, '-|');
die $! if not defined $pid;
$exec_probe->() if not $pid;

local $/;
my $result = <$output>;
close($output);

isnt($?, 0, 'original integration test rejects a post-copy install failure')
    or diag($result);
like(
    $result,
    qr/not ok .* Build install succeeds.*injected post-copy SPc failure/s,
    'failure output identifies the install assertion and injected error',
);
